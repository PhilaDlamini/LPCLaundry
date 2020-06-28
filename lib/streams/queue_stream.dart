import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:laundryqueue/data_handlers/queue_isolate_handler.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/models/User.dart';

class QueueStream {

  final StreamController<List<QueueData>> _controller = StreamController<List<QueueData>>();
  final Map<String, Stream<DocumentSnapshot>> queueDataStreams;
  final User user;
  final BuildContext context;

  List<QueueData> queueDataList;
  QueueInstance lastDrierQueueInstance;
  QueueInstance lastWasherQueueInstance;
  bool machineUseConfirmed; //For starting the isolates later

  QueueStream(this.context, {this.queueDataStreams, this.user}) {

    //The list that holds up-to-date data
    queueDataList = List<QueueData>();

    //Loop through all the streams and listen for data changes. Return it was queue instance
    for(String key in queueDataStreams.keys) {

      Stream<DocumentSnapshot> stream = queueDataStreams[key];

      stream.listen((snapshot) {
        if(!(snapshot.data == null)) {

          QueueData queueData = QueueData(data: {key: snapshot.data}, user: user);

          //Make sure there are no duplicates before adding
          queueDataList.removeWhere((item) => item.key == queueData.key);
          queueDataList.add(queueData);

          //TODO: Remove this later
          print('key: $key, data: ${snapshot.data}');

        }
        _controller.sink.add(queueDataList);
        QueueIsolateHandler(context, user: user, queueDataList: queueDataList).startIsolates();
      },
      onError: (e) {
        print('Error getting data! $e');
      });
    }
  }

  Stream<List<QueueData>> get queueStream => _controller.stream;

}
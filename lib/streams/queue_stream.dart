import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:laundryqueue/data_handler_models/QueueIsolateHandler.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/data_handler_models/QueueData.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/queue_isolate.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class QueueStream {

  final StreamController<List<QueueData>> _controller = StreamController<List<QueueData>>();
  final Map<String, Stream<DocumentSnapshot>> queueDataStreams;
  final User user;

  List<QueueData> queueDataList;
  QueueInstance lastDrierQueueInstance;
  QueueInstance lastWasherQueueInstance;
  bool machineUseConfirmed; //For starting the isolates later

  QueueStream({this.queueDataStreams, this.user}) {

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

          print('Key: $key,    data: ${snapshot.data}');

        }
        _controller.sink.add(queueDataList);
        QueueIsolateHandler(user: user, queueDataList: queueDataList).startIsolates();
      },
      onError: (e) {
        print('Error getting data! $e');
      });
    }
  }

  Stream<List<QueueData>> get queueStream => _controller.stream;

}
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundryqueue/models/QueueData.dart';
import 'package:laundryqueue/models/User.dart';

class QueueStream {

  final StreamController<List<QueueData>> _controller = StreamController<List<QueueData>>();
  //Map of streams and the info on the machine that the stream is for (fire database service)
  final Map<String, Stream<DocumentSnapshot>> queueDataStreams;
  final User user;

  QueueStream({this.queueDataStreams, this.user}) {

    List<QueueData> queueDataList = List<QueueData>();

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

      },
      onError: (e) {
        print('Error getting data! $e');
      });
    }
  }

  Stream<List<QueueData>> get queueStream => _controller.stream;
}
import 'dart:async';
import 'package:laundryqueue/models/QueueInstance.dart';

class QueueProgressStream {
  final StreamController<double> _controller = StreamController<double>();
  final QueueInstance userQueue;
  final String type;

  QueueProgressStream({this.userQueue, this.type}) {
    //Get the duration between queue time and start time
    Duration duration = (type == 'till queueStart')
        ? DateTime.fromMillisecondsSinceEpoch(userQueue.startTimeInMillis)
            .difference(DateTime.fromMillisecondsSinceEpoch(
                userQueue.timeQueuedInMillis))
        : DateTime.fromMillisecondsSinceEpoch(userQueue.endTimeInMillis)
            .difference(DateTime.fromMillisecondsSinceEpoch(
                userQueue.startTimeInMillis));

    Timer.periodic(Duration(seconds: 1), (timer) {
      //Get the time left until queuing
      Duration timeLeft = (type == 'till queueStart')
          ? userQueue.timeLeftTillQueueStart
          : userQueue.timeLeftTillQueueEnd;

      double value = 1 - ((timeLeft.inSeconds) / duration.inSeconds);

      if (timeLeft.inSeconds <= 0) {
        timer.cancel();
      }

      _controller.sink.add(value);
    });
  }

  Stream<double> get stream => _controller.stream;
}

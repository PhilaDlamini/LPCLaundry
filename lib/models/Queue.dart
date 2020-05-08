import 'User.dart';

class Queue {
  final User user;
  final String location;
  final String which;
  final int startTimeInMillis;
  final int endTimeInMillis;
  final int timeQueuedInMillis;

  Queue({this.user, this.which, this.location, this.startTimeInMillis, this.endTimeInMillis, this.timeQueuedInMillis});

  factory Queue.fromMap(Map<String, dynamic> data) {
    return Queue(
      user: User.fromMap(data['user']),
      startTimeInMillis: data['startTime'],
      endTimeInMillis: data['endTime'],
      timeQueuedInMillis: data['timeQueued']
    );
  }

  Map<String, dynamic> toQueuingMap() {
    return {
      'user' : user.toMap(),
      'startTime' : startTimeInMillis,
      'endTime': endTimeInMillis,
      'timeQueued': timeQueuedInMillis
    };
  }

  Map<String, String> get displayableTime {
    DateTime startTime = DateTime.fromMillisecondsSinceEpoch(startTimeInMillis);
    DateTime endTime = DateTime.fromMillisecondsSinceEpoch(endTimeInMillis);

    //Make sure the minutes are two-digit

    return {
      'startTime' : '${startTime.hour}:${startTime.minute}',
      'endTime' : '${endTime.hour}:${endTime.minute}',
    };
  }
  
  Duration get timeLeftTillQueueStart {
    DateTime startTime = DateTime.fromMillisecondsSinceEpoch(startTimeInMillis);
    return startTime.difference(DateTime.now());
  }

  Duration get timeLeftTillQueueEnd {
    DateTime startTime = DateTime.fromMillisecondsSinceEpoch(endTimeInMillis);
    return startTime.difference(DateTime.now());
  }
}
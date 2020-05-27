import 'package:equatable/equatable.dart';

import 'User.dart';

class QueueInstance extends Equatable{
  final User user;
  final String location;
  final String which;
  final int startTimeInMillis;
  final int endTimeInMillis;
  final int timeQueuedInMillis;

  QueueInstance({this.user, this.which, this.location, this.startTimeInMillis, this.endTimeInMillis, this.timeQueuedInMillis});

  factory QueueInstance.fromMap(Map<String, dynamic> data) {
    return QueueInstance(
      user: data['user'] != null ? User.fromMap(data['user']) : null,
      startTimeInMillis: data['startTime'],
      endTimeInMillis: data['endTime'],
      timeQueuedInMillis: data['timeQueued'],
      which: data['which'],
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

  Map<String, dynamic> toSummaryMap(String machineNumber) {
    return {
      'which' : machineNumber,
      'endTime' : endTimeInMillis,
      'timeQueued' : timeQueuedInMillis
    };
  }

  Map<String, String> get displayableTime {
    DateTime startTime = startTimeInMillis != null ? DateTime.fromMillisecondsSinceEpoch(startTimeInMillis) : null;
    DateTime endTime = DateTime.fromMillisecondsSinceEpoch(endTimeInMillis);
    DateTime timeQueued = DateTime.fromMillisecondsSinceEpoch(timeQueuedInMillis);

    //Make sure the minutes are two-digit

    return {
      'startTime' : startTime != null ? '${startTime.hour}:${startTime.minute}' : null,
      'endTime' : '${endTime.hour}:${endTime.minute}',
      'timeQueued' : '${timeQueued.hour}:${timeQueued.minute}'
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

  String toString() => 'User: $user, endTime: $endTimeInMillis, timeQueued: $timeQueuedInMillis';

  @override
  List<Object> get props => [user, startTimeInMillis, endTimeInMillis, timeQueuedInMillis];

}

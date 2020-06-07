import 'package:equatable/equatable.dart';
import 'package:laundryqueue/services/database.dart';

import 'User.dart';

class QueueInstance extends Equatable{
  final User user;
  final String location;
  final String which;
  final int startTimeInMillis;
  final int endTimeInMillis;
  final int timeQueuedInMillis;
  final List<String> usersQueuedWith;

  QueueInstance({this.user, this.which, this.location, this.usersQueuedWith, this.startTimeInMillis, this.endTimeInMillis, this.timeQueuedInMillis});

  factory QueueInstance.fromMap(Map<String, dynamic> data) {

    //Convert the list of users queued with from dynamic to strings
    List<dynamic> rawList = data['queuedWith'];
    List<String> queuedWith = rawList.map((item) => '$item').toList();

    return QueueInstance(
      user: data['user'] != null ? User.fromMap(data['user']) : null,
      startTimeInMillis: data['startTime'],
      endTimeInMillis: data['endTime'],
      timeQueuedInMillis: data['timeQueued'],
      which: data['which'],
      usersQueuedWith: queuedWith
    );
  }

  Map<String, dynamic> toQueuingMap() {
    return {
      'user' : user.toMap(),
      'startTime' : startTimeInMillis,
      'endTime': endTimeInMillis,
      'timeQueued': timeQueuedInMillis,
      'queuedWith' : usersQueuedWith
    };
  }

  Map<String, dynamic> toSummaryMap(String machineNumber) {
    return {
      'which' : machineNumber,
      'endTime' : endTimeInMillis,
      'timeQueued' : timeQueuedInMillis,
       'queuedWith' : usersQueuedWith,
      'startTime' : startTimeInMillis,


      //Do we save who this user queued with too?
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

  Future<String> get namesOfUsersQueuedWith async {
    String names = '';
    for(int i = 0; i < usersQueuedWith.length; i++) {
      String uid = usersQueuedWith[i];
      if(i == usersQueuedWith.length - 1) {
        names += '${(await DatabaseService(uid: uid).getUser()).name}';
      } else {
        names += '${(await DatabaseService(uid: uid).getUser()).name}, ';

      }}
    return names;
  }

  bool get isQueuedJointly {
    return usersQueuedWith.isNotEmpty;
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

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
    //Note: users queued under other users will not save the summary as they do not start the isolates
    return {
      'which' : machineNumber,
      'endTime' : endTimeInMillis,
      'timeQueued' : timeQueuedInMillis,
       'queuedWith' : usersQueuedWith,
      'startTime' : startTimeInMillis,
    };
  }

  Map<String, String> get displayableTime {
    DateTime startTime = startTimeInMillis != null ? DateTime.fromMillisecondsSinceEpoch(startTimeInMillis) : null;
    DateTime endTime = DateTime.fromMillisecondsSinceEpoch(endTimeInMillis);
    DateTime timeQueued = DateTime.fromMillisecondsSinceEpoch(timeQueuedInMillis);

    //Make sure the time is two-digit
    String startTimeMinute = '${startTime.minute}'.length == 1 ? '0${startTime.minute}' : '${startTime.minute}';
    String startTimeHour = '${startTime.hour}'.length == 1 ? '0${startTime.hour}' : '${startTime.hour}';
    String endTimeMinute = '${endTime.minute}'.length == 1 ? '0${endTime.minute}' : '${endTime.minute}';
    String endTimeHour = '${endTime.hour}'.length == 1 ? '0${endTime.hour}' : '${endTime.hour}';
    String timeQueuedMinute = '${timeQueued.minute}'.length == 1 ? '0${timeQueued.minute}' : '${timeQueued.minute}';
    String timeQueuedHour = '${timeQueued.hour}'.length == 1 ? '0${timeQueued.hour}' : '${timeQueued.hour}';

    return {
      'startTime' : startTime != null ? '$startTimeHour:$startTimeMinute' : null,
      'endTime' : '$endTimeHour:$endTimeMinute',
      'timeQueued' : '$timeQueuedHour:$timeQueuedMinute'
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

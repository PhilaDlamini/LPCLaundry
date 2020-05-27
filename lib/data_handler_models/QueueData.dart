import 'package:laundryqueue/models/QueueInstance.dart';
import '../models/User.dart';

class QueueData {

  final Map<String, dynamic> data;
  final User user;
  String key;

  QueueData({this.data, this.user}) {
    key = data.keys.toList()[0];
  }

  String get whichMachine => key.split(':')[0].trim();

  String get machineNumber => key.split(':')[1].trim();

  bool get userQueued {
    for(QueueInstance queue in queueInstances) {
      if(queue.user.uid == user.uid) {
        return true;
      }
    }
    return false;
  }

  List<QueueInstance> get queueInstances {
    List<QueueInstance> users = List<QueueInstance>();

    for(var user in data[key]['queue']) {
      users.add(QueueInstance.fromMap(user));
    }
    return users;
  }

  String toString() => '$data';
}
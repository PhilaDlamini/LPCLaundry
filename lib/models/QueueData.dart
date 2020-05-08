import 'package:laundryqueue/models/Queue.dart';
import 'User.dart';

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
    for(Queue queue in queueInstances) {
      if(queue.user.uid == user.uid) {
        return true;
      }
    }
    return false;
  }

  List<Queue> get queueInstances {
    List<Queue> users = List<Queue>();

    for(var user in data[key]['queue']) {
      users.add(Queue.fromMap(user));
    }
    return users;
  }

}
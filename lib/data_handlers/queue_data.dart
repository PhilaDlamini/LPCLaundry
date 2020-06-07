import 'package:equatable/equatable.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import '../models/User.dart';

class QueueData extends Equatable{

  final Map<String, dynamic> data;
  final User user;
  String key;

  QueueData({this.data, this.user}) {
    key = data.keys.toList()[0];
  }

  String get whichMachine => key.split(':')[0].trim();

  String get machineNumber => key.split(':')[1].trim();

  bool get userQueued {
    bool queued = false;
    for(QueueInstance queue in queueInstances) {
      if(queue.user.uid == user.uid) {
        queued = true;
      }
    }

    if(queued || queuedUnderOtherUser) {
      return true;
    }
    return false;
  }

  bool get queuedUnderOtherUser {
    for(QueueInstance queue in queueInstances) {
      for(String uid in queue.usersQueuedWith) {
        if(uid == user.uid) {
          return true;
        }
      }
    }
    return false;
  }

  QueueInstance get queueInstanceUnder {
    for(QueueInstance queue in queueInstances) {
      for(String uid in queue.usersQueuedWith) {
        if(uid == user.uid) {
          return queue;
        }
      }
    }
    return QueueInstance();
  }

  List<QueueInstance> get queueInstances {
    List<QueueInstance> instances = List<QueueInstance>();

    for(var queueInstance in data[key]['queue']) {
      instances.add(QueueInstance.fromMap(queueInstance));
    }
    return instances;
  }

  String toString() => '$data';

  @override
  List<Object> get props => [queueInstances];
}

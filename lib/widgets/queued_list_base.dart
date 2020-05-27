import 'dart:async';
import 'package:flutter/material.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/queue_isolate.dart';
import 'package:laundryqueue/streams/count_down.dart';
import 'package:laundryqueue/streams/queue_progress_stream.dart';
import 'package:laundryqueue/widgets/list_item.dart';

class QueueListBase extends StatefulWidget {
  final List<QueueInstance> usersInQueue;
  final QueueInstance userQueueInstance;
  final String machineType;
  final String machineNumber;
  final bool enableQueuing;
  final Function toggle;
  final String whichQueue;

  QueueListBase({this.usersInQueue,
      this.toggle,
      this.enableQueuing,
      this.userQueueInstance,
      this.whichQueue,
      this.machineNumber,
      this.machineType});

  @override
  State<StatefulWidget> createState() => _QueueListBaseState();
}

class _QueueListBaseState extends State<QueueListBase> {
  User user;
  String positionInQueue;
  List<QueueInstance> usersQueued;
  QueueInstance userQueue;
  QueueIsolate _startTimeIsolate;

  int _indexOfUser() {
    int index;
    for (int i = 0; i < usersQueued.length; i++) {
      if (usersQueued[i].user.uid == userQueue.user.uid) {
        index = i;
        break;
      }
    }
    return index;
  }

  @override
  void initState() {
    usersQueued = widget.usersInQueue;
    userQueue = widget.userQueueInstance;
    positionInQueue = _indexOfUser() == 0
        ? 'You are first in the queue'
        : _indexOfUser() == 1
            ? 'There is ${_indexOfUser()} person ahead of you'
            : 'There are ${_indexOfUser()} people ahead of you';

    _startTimeIsolate = QueueIsolate(
      duration: userQueue.timeLeftTillQueueStart,
      onFinished: () {
        widget.toggle(); //Switch to the QueueInProgress page
        _startTimeIsolate.stop();
      }
    );

    _startTimeIsolate.start();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    user = DataInheritedWidget.of(context).user;

        return Scaffold(
          body: Column(
            children: <Widget>[
              SizedBox(height: 16),
              Expanded(
                flex: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.brown,
                  ),
                  title: Text('Me'),
                  subtitle: Text(
                    'Block ${user.block}\n${widget.machineType} #${widget.machineNumber}\n@${userQueue.displayableTime['startTime']}',
                    maxLines: 3,
                  ),
                  trailing: Container(
                    width: 100,
                    height: 100,
                    child: StreamBuilder(
                      stream: CountDown(duration: userQueue.timeLeftTillQueueStart)
                          .stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          //In case the user has left, send them to the QueueInProgress page if this is 0
                          if(snapshot.data.trim() == '0s') {
                            Timer.run(widget.toggle);
                          }
                          return Text(snapshot.data);
                        }
                        return Text('');
                      },
                    ),
                  ),
                ),
              ),
              StreamBuilder(
                  stream: QueueProgressStream(
                      type: 'till queueStart', userQueue: userQueue)
                      .stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return LinearProgressIndicator(value: snapshot.data);
                    }

                    return Container();
                  }),
              Text(positionInQueue),
              Expanded(
                flex: 5,
                child: ListView.builder(
                  itemCount: usersQueued.length,
                  itemBuilder: (context, index) {
                    return ListItem(
                        queue: usersQueued[index],
                        me: usersQueued[index].user.uid == userQueue.user.uid);
                  },
                ),
              ),
              Offstage(
                  offstage: false,//!widget.enableQueuing,
                  child: RaisedButton(
                    child: Text('Queue for other'),
                    onPressed: () async {
                      await AuthService().signOut(); //Remove later: enabled you to shift between users.
//                  Navigator.push(
//                    context,
//                    MaterialPageRoute(
//                      builder: (context) => QueuePage(
//                        isWashing: widget.machineType == 'drier' ? true : false,
//                        isDrying: widget.machineType == 'washer' ? true : false,
//                      ),
//                      settings: RouteSettings(
//                        arguments: user,
//                      ),
//                    ),
//                  );
                    },
                  ))
            ],
          ),
        );



  }
}

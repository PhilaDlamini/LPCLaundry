import 'dart:async';

import 'package:flutter/material.dart';
import 'package:laundryqueue/inherited_widgets/user_inherited_widget.dart';
import 'package:laundryqueue/models/Queue.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/home/pages/queue_page.dart';
import 'package:laundryqueue/streams/count_down.dart';
import 'package:laundryqueue/streams/queue_progress_stream.dart';
import 'package:laundryqueue/widgets/list_item.dart';

class QueueListBase extends StatefulWidget {
  final List<Queue> usersInQueue;
  final Queue userQueueInstance;
  final String machineType;
  final String machineNumber;
  final bool enableQueuing;
  final Function toggle;

  QueueListBase(
      {this.usersInQueue,
      this.toggle,
      this.enableQueuing,
      this.userQueueInstance,
      this.machineNumber,
      this.machineType});

  @override
  State<StatefulWidget> createState() => _QueueListBaseState();
}

class _QueueListBaseState extends State<QueueListBase> {
  User user;
  String positionInQueue;
  List<Queue> usersQueued;
  Queue userQueue;

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
    usersQueued
        .sort((a, b) => a.startTimeInMillis.compareTo(b.startTimeInMillis));
    positionInQueue = _indexOfUser() == 0
        ? 'You are first in the queue'
        : _indexOfUser() == 1
            ? 'There is ${_indexOfUser()} person ahead of you'
            : 'There are ${_indexOfUser()} people ahead of you';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    user = UserInheritedWidget.of(context).user;

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
                      if (snapshot.data.trim() == '0s') {
                        //Wait for this widget to finish redrawing. Then make the parent redraw so that it shows QueueInProgress
                        Future.delayed(Duration(milliseconds: 50)).then((val) {
                          widget.toggle();
                        });
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
              offstage: !widget.enableQueuing,
              child: RaisedButton(
                child: Text('Queue for other'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QueuePage(
                        isWashing: widget.machineType == 'drier' ? true : false,
                        isDrying: widget.machineType == 'washer' ? true : false,
                      ),
                      settings: RouteSettings(
                        arguments: user,
                      ),
                    ),
                  );
                },
              ))
        ],
      ),
    );
  }
}

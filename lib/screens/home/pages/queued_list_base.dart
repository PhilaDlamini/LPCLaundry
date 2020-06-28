import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/home/pages/choose.dart';
import 'package:laundryqueue/services/queue_isolate.dart';
import 'package:laundryqueue/services/storage.dart';
import 'package:laundryqueue/streams/count_down.dart';
import 'package:laundryqueue/streams/queue_progress_stream.dart';
import 'package:laundryqueue/widgets/custom_list_tile.dart';
import 'package:laundryqueue/widgets/user_item.dart';

class QueueListBase extends StatefulWidget {
  final List<QueueInstance> usersInQueue;
  final QueueInstance userQueueInstance;
  final String machineType;
  final String machineNumber;
  final bool enableQueuing;
  final Function toggle;
  final String whichQueue;
  final bool hideAppBar;
  final bool queuedUnderOtherUser;

  QueueListBase({
      this.usersInQueue,
      this.toggle,
      this.enableQueuing,
      this.userQueueInstance,
      this.hideAppBar = false,
      this.whichQueue,
      this.machineNumber,
    this.queuedUnderOtherUser,
      this.machineType});

  @override
  State<StatefulWidget> createState() => _QueueListBaseState();
}

class _QueueListBaseState extends State<QueueListBase> {
  User user;
  String positionInQueue;
  List<QueueInstance> usersQueued;
  List widgetDataList = List();
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
        ? '1st in queue'
        : _indexOfUser() == 1
            ? '2nd in queue '
            : '${_indexOfUser()} people are ahead of you';

    //Order not to change
    widgetDataList.add(_getUserQueueInfo());
    widgetDataList.add('In queue');
    widgetDataList.addAll(usersQueued);

    _startTimeIsolate = QueueIsolate(
        duration: userQueue.timeLeftTillQueueStart,
        onFinished: () {
          widget.toggle(); //Switch to the QueueInProgress page
          _startTimeIsolate.stop();
        });

    _startTimeIsolate.start();

    super.initState();
  }

  Widget _getUserQueueInfo() {
    return Container(
      height: 114,
      margin: EdgeInsets.only(top: 8),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        child: Container(
            padding: EdgeInsets.only(top: 8, right: 8, left: 8),
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.all(0),
                  title: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: <Widget>[
                        Text(
                          widget.whichQueue == 'washer queue'
                              ? 'Washer'
                              : 'Drier',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Center(child: dot),
                        Text('#${widget.machineNumber}',
                            style: TextStyle(fontSize: 15))
                      ],
                    ),
                  ),
                  subtitle: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: <Widget>[
                            bigDot,
                            Text(positionInQueue,
                                style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                        child: Row(
                          children: <Widget>[
                            bigDot,
                            Text(
                              '${userQueue.displayableTime['startTime']} - ${userQueue.displayableTime['endTime']}',
                              style: TextStyle(fontSize: 14),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.only(top: 24, right: 16),
                    child: StreamBuilder(
                      stream:
                          CountDown(duration: userQueue.timeLeftTillQueueStart)
                              .stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          if (snapshot.data.trim() == '0s') {
                            Timer.run(widget.toggle);
                          }
                          return Text(snapshot.data,
                              style: TextStyle(fontWeight: FontWeight.w500));
                        }
                        return Text('');
                      },
                    ),
                  ),
                ),
                StreamBuilder(
                    stream: QueueProgressStream(
                            type: 'till queueStart', userQueue: userQueue)
                        .stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 3),
                          height: 2,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.grey[300],
                            value: snapshot.data,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.pink[300]),
                          ),
                        );
                      }

                      return Container();
                    }),
              ],
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    user = DataInheritedWidget.of(context).user;

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              elevation: 0,
              leading: GestureDetector(
                  child: Icon(Icons.menu),
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  }),
              title: Text('Block ${user.block} queue'),
              actions: <Widget>[
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: FutureBuilder(
                      future: StorageService(user: user).getImageURL(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            width: 24,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                            ),
                          );
                        }

                        return SizedBox(
                          width: 24,
                          height: 24,
                          child: CircleAvatar(
                            // backgroundImage: NetworkImage(snapshot.data),
                            backgroundColor: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
      body: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Stack(
          children: <Widget>[
            ListView.builder(
              itemCount: widgetDataList.length,
              itemBuilder: (context, index) {
                if (widgetDataList[index] is Widget) {
                  return widgetDataList[index];
                } else if (widgetDataList[index] is String) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'In queue',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                  );
                }

                bool isMe = widgetDataList[index].user.uid == userQueue.user.uid;
                return CustomListTile(
                    usersQueuedWith: widgetDataList[index].usersQueuedWith,
                    queueInstance: widgetDataList[index],
                    isUs: isMe && widgetDataList[index].isQueuedJointly,
                    whichQueue: widget.whichQueue,
                    machineNumber: widget.machineNumber,
                    queuedUnderOtherUser: widget.queuedUnderOtherUser,
                    queueDataList:
                    DataInheritedWidget.of(context).queueDataList,
                    isMe: isMe
                );

              },
            ),
          ],
        ),
      ),
      floatingActionButton: Offstage(
        offstage: !widget.enableQueuing,
        child: FloatingActionButton.extended(
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChooseUsers(
                  isWashing: false,
                  isDrying: true,
                  user: user,
                  washerQueueInstance: userQueue,
                ),
              ),
            );
          },
          icon: Icon(Icons.queue),
          label: Text('Queue for drier'),
        ),
      ),
    );
  }
}

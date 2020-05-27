import 'dart:async';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/queue_isolate.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/streams/count_down.dart';
import 'package:laundryqueue/streams/queue_progress_stream.dart';

class QueueInProgress extends StatefulWidget {
  final QueueInstance userQueueInstance;
  final String title;
  final String whichQueue;
  final String machineNumber;

  QueueInProgress(
      {this.userQueueInstance,
      this.title,
      this.machineNumber,
      this.whichQueue});

  static String getKey(String whichQueue) => whichQueue == 'washer queue'
      ? Preferences.WASHER_USE_CONFIRMED
      : Preferences.DRIER_USE_CONFIRMED;

  @override
  State<StatefulWidget> createState() => _QueueInProgressState();
}

class _QueueInProgressState extends State<QueueInProgress> {
  final List<String> timeExtensions = [
    'Select duration',
    '5 minutes',
    '10 minutes',
    '20 minutes',
    '40 minutes',
    '60 minutes'
  ];
  Duration _confirmationLeeWay;
  bool machineUseConfirmed;
  bool askingForExtension =
      false; //Temporary to enable the user to extend time TODO: Redesign screen and fix this
  String key;
  String currentTimeExtension = 'Select duration';
  int _secondsLeft;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _showAlertDialog() async {
    String machine =
        widget.whichQueue == 'washer queue' ? 'washing machine' : 'drier';

    if (_confirmationLeeWay.inSeconds < 60 && !machineUseConfirmed) {
      showDialog(
          barrierDismissible: false,
          builder: (context) => AlertDialog(
                title: Text('Confirm machine use'),
                content: Container(
                  height: 150,
                  child: Column(
                    children: <Widget>[
                      Text(
                          'Confirm that you have started using the $machine. Otherwise you will be skipped and others will go before you'),
                      StreamBuilder(
                          stream: CountDown(
                                  duration: Duration(seconds: _secondsLeft))
                              .stream,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              //Remove the alert dialog when we get to zero (at his point too, the isolate will skip the user)
                              if (snapshot.data.trim() == '0s') {
                                Timer.run(() => Navigator.pop(context));
                              }

                              return Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Center(
                                    child: Column(
                                      children: <Widget>[
                                        Text('Time Left'),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Icon(
                                              Icons.timelapse,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4.0),
                                              child: Text('${snapshot.data}'),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ));
                            }

                            return Container();
                          })
                    ],
                  ),
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Un-queue'),
                    onPressed: () async {
                      //Remove the alert dialog
                      Navigator.pop(context);

                      //Un-queue this user
                      await DatabaseService(
                              whichQueue: widget.whichQueue,
                              location:
                                  'Block ${widget.userQueueInstance.user.block}',
                              machineNumber: widget.machineNumber)
                          .unQueueUser(queue: widget.userQueueInstance);
                    },
                  ),
                  FlatButton(
                    child: Text('Confirm'),
                    onPressed: () async {
                      Navigator.pop(context);
                      await Preferences.updateBoolData(key, true);
                      setState(() {});
                    },
                  )
                ],
              ),
          context: context);
    }
  }

  Future isMachineUseConfirmed() async {
    machineUseConfirmed = await Preferences.getBoolData(key);
    return 'Done';
  }

  Future resetMachineConfirmation() async {
    await Preferences.updateBoolData(key, false);
    return 'Done';
  }

  @override
  void initState() {
    _confirmationLeeWay = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(
            widget.userQueueInstance.startTimeInMillis));
    _secondsLeft = 60 - _confirmationLeeWay.inSeconds;
    key = QueueInProgress.getKey(widget.whichQueue);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Fetch the data about machine use confirmation
    return FutureBuilder(
        future: isMachineUseConfirmed(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          } else {
            //If machine use is not confirmed, show the alert dialog
            Timer.run(_showAlertDialog);

            //Build the widget for the screen
            return StreamBuilder(
                stream: CountDown(
                        duration: widget.userQueueInstance.timeLeftTillQueueEnd)
                    .stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Scaffold(
                      appBar: AppBar(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        title: Text(
                          widget.title,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal),
                        ),
                        actions: <Widget>[
                          Icon(
                            Icons.more_vert,
                            color: Colors.black,
                          )
                        ],
                      ),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            StreamBuilder(
                                stream: QueueProgressStream(
                                        userQueue: widget.userQueueInstance,
                                        type: 'till queueEnd')
                                    .stream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.brown[200]),
                                      child: CircularProgressIndicator(
                                        value: snapshot.data,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  }

                                  return Container();
                                }),
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                'Done @${widget.userQueueInstance.displayableTime['endTime']}',
                                style: TextStyle(fontSize: 25),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                '${snapshot.data}',
                                style: TextStyle(fontSize: 25),
                              ),
                            ),
                            SizedBox(
                              height: 100,
                            ),
                            Offstage(
                                //TODO: Modify upon redesigning this screen
                                offstage: !askingForExtension,
                                child: Form(
                                  key: _formKey,
                                  child: DropdownButtonFormField<String>(
                                    items: timeExtensions.map((item) {
                                      return DropdownMenuItem(
                                        child: Text(item),
                                        value: item,
                                      );
                                    }).toList(),
                                    onChanged: (newItem) => setState(
                                        () => currentTimeExtension = newItem),
                                    value: currentTimeExtension,
                                  ),
                                )),
                            RaisedButton(
                                child: Text('Quit'),
                                onPressed: () async {

                                  await AuthService().signOut(); //TODO: Remove this
//                                  showDialog(
//                                    context: context,
//                                    barrierDismissible: true,
//                                    builder: (context) => AlertDialog(
//                                      title: Text('Leave queue'),
//                                      content: Text(
//                                          'If you quit, you will be removed from the queue even before you are done using the machine, and other users'
//                                          'will go in your place. To use this machine, you will have to queue again.\nAre you sure you want to quit?'),
//                                      actions: <Widget>[
//                                        FlatButton(
//                                          child: Text('Cancel'),
//                                          onPressed: () {
//                                            Navigator.pop(context);
//                                          },
//                                        ),
//                                        FlatButton(
//                                          child: Text('Yes'),
//                                          onPressed: () async {
//                                            Navigator.pop(context);
//
//                                            //Un-queue this user
//                                            await DatabaseService(
//                                                    whichQueue: widget.whichQueue,
//                                                    location: 'Block ${widget.userQueueInstance.user.block}',
//                                                    machineNumber: widget.machineNumber)
//                                                .unQueueUser(
//                                                    queue: widget.userQueueInstance);
//                                          },
//                                        ),
//                                      ],
//                                    ),
//                                  );
                                }),
                            RaisedButton(
                                child: Text('Extend time'),
                                onPressed: () async {
                                  if (askingForExtension) {

                                    Duration timeExtension = Duration(minutes: currentTimeExtension == 'Select Duration' ? 0 :
                                    int.parse(currentTimeExtension.split(' ')[0]));

                                    print('The extension asked for in minutes ${timeExtension.inMinutes}');

                                   await DatabaseService(
                                            whichQueue: widget.whichQueue,
                                            machineNumber: widget.machineNumber,
                                            location: 'Block ${widget.userQueueInstance.user.block}')
                                        .grantExtension(
                                      queueInstance: widget.userQueueInstance,
                                      timeExtensionInMillis: timeExtension.inMilliseconds,
                                      queueDataList: DataInheritedWidget.of(context).queueDataList,
                                    );
                                  }

                                  askingForExtension = true;

                                  //TODO: Implement method to extend time
                                }),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container();
                });
          }
        });
  }
}

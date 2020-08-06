import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/screens/home/pages/choose.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/services/storage.dart';
import 'package:laundryqueue/streams/count_down.dart';
import 'package:laundryqueue/streams/queue_progress_stream.dart';
import 'package:laundryqueue/widgets/custom_dialog.dart';
import 'package:laundryqueue/widgets/liquid_progress.dart';

class QueueInProgress extends StatefulWidget {
  final QueueInstance userQueueInstance;
  final String title;
  final String whichQueue;
  final String machineNumber;
  final bool queueUnderOtherUser;
  final bool enableQueuing;

  QueueInProgress(
      {this.userQueueInstance,
      this.title,
      this.machineNumber,
      this.queueUnderOtherUser,
      this.enableQueuing,
      this.whichQueue});

  static String getKey(String whichQueue) => whichQueue == 'washer queue'
      ? Preferences.WASHER_USE_CONFIRMED
      : Preferences.DRIER_USE_CONFIRMED;

  @override
  State<StatefulWidget> createState() => _QueueInProgressState();
}

class _QueueInProgressState extends State<QueueInProgress>
    with SingleTickerProviderStateMixin {
  List<QueueData> _queueDataList;
  Duration _confirmationLeeWay;
  bool machineUseConfirmed;
  bool askingForExtension = false;
  String key;
  int _secondsLeft;
  bool queuedUnderOtherUser;
  QueueInstance userQueueInstance;

  void extendTime(Duration duration) async {
    await DatabaseService(
            whichQueue: widget.whichQueue,
            machineNumber: widget.machineNumber,
            location: 'Block ${widget.userQueueInstance.user.block}')
        .grantExtension(
      queueInstance: widget.userQueueInstance,
      timeExtensionInMillis: duration.inMilliseconds,
      queueDataList: DataInheritedWidget.of(context).queueDataList,
    );

    //Notify isolates of this extensions (so the queue is not finished at the previous time)
    _notifyIsolateOfRemoval();

    //Also, save that at extension was granted for this queue
    _extensionGranted();
  }

  void _showSkipAlertDialog() async {
    //Check if the machine use is confirmed before showing the alert dialog
    await isMachineUseConfirmed();
    String machine =
        widget.whichQueue == 'washer queue' ? 'washing machine' : 'drier';

    if (_confirmationLeeWay.inSeconds < 60 && !machineUseConfirmed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: 'Confirm machine use',
        message:
            'Confirm that you have started using the $machine. Otherwise, you will be skipped and others will go before you',
        showTimer: true,
        negativeButtonName: 'Un-queue',
        negativeOnTap: () async {
          //Notifies the isolate for this queue that the queue no longer exists
          _notifyIsolateOfRemoval();

          //Remove the alert dialog
          Navigator.pop(context);

          //Un-queue this user
          await DatabaseService(
                  whichQueue: widget.whichQueue,
                  location: 'Block ${widget.userQueueInstance.user.block}',
                  machineNumber: widget.machineNumber)
              .unQueueUser(
                  queue: widget.userQueueInstance,
                  queueDataList: _queueDataList);
        },
        positiveOnTap: () async {
          Navigator.pop(context);
          await Preferences.updateBoolData(key, true);
          setState(() {});
        },
        positiveButtonName: 'Confirm',
        secondsLeft:  _secondsLeft,
      ),
    );
      }
  }

  void _showSelectTimeDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: 'Extend by',
        negativeButtonName: 'Cancel',
        positiveButtonName: 'OK',
        extendTime: extendTime,
        radioButton: true,
      ),
    );
  }

  Future _notifyIsolateOfRemoval() async {
    if (widget.whichQueue == 'washer queue') {
      await Preferences.updateBoolData(
          Preferences.WASHER_QUEUE_REMOVED_AT_TIME, true);
    } else {
      await Preferences.updateBoolData(
          Preferences.DRIER_QUEUE_REMOVED_AT_TIME, true);
    }
  }

  Future isMachineUseConfirmed() async {
    machineUseConfirmed = await Preferences.getBoolData(key);
    return 'Done';
  }

  Future _extensionGranted() async {
    if (widget.whichQueue == 'washer queue') {
      await Preferences.updateBoolData(
          Preferences.WASHER_QUEUE_EXTENSION_GRANTED, true);
    } else {
      await Preferences.updateBoolData(
          Preferences.DRIER_QUEUE_EXTENSION_GRANTED, true);
    }
  }

  Widget getBottomButtons(bool isLandscape) {
    return Expanded(
      flex: isLandscape ? 2 : 1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          circularButton(
              icon: Icon(Icons.delete, color: Colors.blueGrey),
              onTap: queuedUnderOtherUser
                  ? null
                  : () async {
                      showUnQueueConfirmationDialog(
                        context,
                        onConfirmed: () async {
                          //Notify isolates of removal
                          await _notifyIsolateOfRemoval();

                          //Remove the alert dialog
                          Navigator.pop(context);

                          //Un-queue this user
                          await DatabaseService(
                                  whichQueue: widget.whichQueue,
                                  location:
                                      'Block ${widget.userQueueInstance.user.block}',
                                  machineNumber: widget.machineNumber)
                              .unQueueUser(
                                  queue: widget.userQueueInstance,
                                  queueDataList: _queueDataList);
                        },
                      );
                    }),
          circularButton(
              icon: Icon(Icons.extension, color: Colors.blueGrey),
              onTap: queuedUnderOtherUser ? null : _showSelectTimeDialog),
          Offstage(
              offstage: !widget.enableQueuing,
              child: circularButton(
                icon: Icon(Icons.queue, color: Colors.blueGrey),
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChooseUsers(
                        isWashing: false,
                        isDrying: true,
                        user: userQueueInstance.user,
                        washerQueueInstance: userQueueInstance,
                      ),
                    ),
                  );
                },
              ))
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(QueueInProgress oldWidget) {
    if (userQueueInstance != oldWidget.userQueueInstance) {
      setState(() {
        userQueueInstance = widget.userQueueInstance;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    queuedUnderOtherUser = widget.queueUnderOtherUser;
    userQueueInstance = widget.userQueueInstance;
    _confirmationLeeWay = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(userQueueInstance.startTimeInMillis));
    _secondsLeft = 60 - _confirmationLeeWay.inSeconds;
    key = QueueInProgress.getKey(widget.whichQueue);
    if (!queuedUnderOtherUser) {
      _showSkipAlertDialog();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _queueDataList = DataInheritedWidget.of(context).queueDataList;
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[100],
        elevation: 0,
        leading: GestureDetector(
            child: Icon(Icons.menu),
            onTap: () {
              Scaffold.of(context).openDrawer();
            }),
        title: Text(widget.title),
        actions: <Widget>[
          Center(
            child: StreamBuilder(
              stream:
                  CountDown(duration: userQueueInstance.timeLeftTillQueueEnd)
                      .stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    padding: EdgeInsets.only(right: 16),
                    child: Text(
                      '${snapshot.data}',
                      style: TextStyle(),
                    ),
                  );
                }

                return Container();
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder(
          stream: QueueProgressStream(
                  type: 'till queueEnd', userQueue: userQueueInstance)
              .stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            return Stack(
              children: <Widget>[
                LiquidProgress(
                  value: snapshot.data,
                ),
                Column(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: isLandscape
                          ? Center(
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.greenAccent,
                                      Colors.white,
                                      Colors.grey[100]
                                    ],
                                  )),
                              child: Center(
                                  child: Text(
                                '${(snapshot.data * 100).round()}%',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                              )),
                            ),
                          )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.greenAccent,
                                          Colors.white,
                                          Colors.grey[100]
                                        ],
                                      )),
                                  child: Center(
                                      child: Text(
                                    '${(snapshot.data * 100).round()}%',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700),
                                  )),
                                ),
                                Container(
                                  width: 200,
                                  child: Center(
                                    child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 16.0),
                                        child: Text(
                                          'Ends ${widget.userQueueInstance.displayableTime['endTime']}',
                                        )),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    getBottomButtons(isLandscape)
                  ],
                ),
              ],
            );
          }),
    );
  }
}

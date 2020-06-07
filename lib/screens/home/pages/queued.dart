import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/home/pages/queue_in_progress.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/screens/home/pages/queued_list_base.dart';

class Queued extends StatefulWidget {
  final QueueData washerQueueData;
  final QueueData drierQueueData;

  Queued({this.washerQueueData, this.drierQueueData});

  @override
  State<StatefulWidget> createState() => _QueuedState();
}

class _QueuedState extends State<Queued> {

  User user;
  Widget washerPage;
  Widget drierPage;
  QueueInstance userDrierQueueInstance;
  QueueInstance userWasherQueueInstance;
  QueueData washerQueueData;
  QueueData drierQueueData;
  bool hasWasherQueueData;
  bool hasDrierQueueData;

  bool _queueInProgress(QueueInstance queue) {
    if (queue == null) {
      return false;
    }

    DateTime startTime =
        DateTime.fromMillisecondsSinceEpoch(queue.startTimeInMillis);
    return startTime.isBefore(DateTime.now());
  }

  Future _initialize() async {
    hasWasherQueueData = washerQueueData != null;
    hasDrierQueueData = drierQueueData != null;

    userWasherQueueInstance = (hasWasherQueueData)
        ? washerQueueData.queuedUnderOtherUser
            ? washerQueueData.queueInstanceUnder
            : washerQueueData.queueInstances
                .singleWhere((queue) => queue.user.uid == user.uid)
        : null;

    userDrierQueueInstance = (hasDrierQueueData)
        ? drierQueueData.queuedUnderOtherUser
            ? drierQueueData.queueInstanceUnder
            : drierQueueData.queueInstances
                .singleWhere((queue) => queue.user.uid == user.uid)
        : null;

    //Initialize the pages
    washerPage = _queueInProgress(userWasherQueueInstance)
        ? QueueInProgress(
            userQueueInstance: userWasherQueueInstance,
            title: 'Washing in progress',
            whichQueue: 'washer queue',
            enableQueuing: !hasDrierQueueData,
            machineNumber: widget.washerQueueData.machineNumber,
            queueUnderOtherUser: washerQueueData.queuedUnderOtherUser,
          )
        : hasWasherQueueData
            ? QueueListBase(
                whichQueue: 'washer queue',
                usersInQueue: widget.washerQueueData.queueInstances,
                userQueueInstance: userWasherQueueInstance,
                machineNumber: widget.washerQueueData.machineNumber,
                machineType: widget.washerQueueData.whichMachine,
                enableQueuing: !hasDrierQueueData,
                toggle: _toggle,
              )
            : null;

    drierPage = _queueInProgress(userDrierQueueInstance)
        ? QueueInProgress(
            userQueueInstance: userDrierQueueInstance,
            title: 'Drying in progress',
            whichQueue: 'drier queue',
            enableQueuing: false,
            machineNumber: widget.drierQueueData.machineNumber,
            queueUnderOtherUser: drierQueueData.queuedUnderOtherUser,
          )
        : hasDrierQueueData
            ? QueueListBase(
                whichQueue: 'drier queue',
                usersInQueue: widget.drierQueueData.queueInstances,
                userQueueInstance: userDrierQueueInstance,
                machineNumber: widget.drierQueueData.machineNumber,
                enableQueuing: false,
                //Once the user has queued for the drier, they can't then queue for the washer (order conflict)
                machineType: widget.drierQueueData.whichMachine,
                toggle: _toggle,
              )
            : null;

    return 'Done';
  }


  void _toggle() {
    setState(() {}); //Redraws
  }

  @override
  void initState() {
    washerQueueData = widget.washerQueueData;
    drierQueueData = widget.drierQueueData;
    super.initState();
  }

  @override
  void didUpdateWidget(Queued oldWidget) {
    if(washerQueueData != oldWidget.washerQueueData || drierQueueData != oldWidget.drierQueueData) {
      setState(() {
        washerQueueData = widget.washerQueueData;
        drierQueueData = widget.drierQueueData;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    user = DataInheritedWidget.of(context).user;

    return FutureBuilder(
      future: _initialize(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        //We display whatever list is not null
        if (washerPage != null && drierPage != null) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                leading: GestureDetector(child: Icon(Icons.menu)),
                actions: <Widget>[
                  GestureDetector(child: Icon(Icons.more_vert))
                ],
                title: Text('Laundry'),
                bottom: TabBar(
                  tabs: <Widget>[
                    Tab(text: 'Washer'),
                    Tab(text: 'Drier'),
                  ],
                ),
              ),
              body: TabBarView(
                children: <Widget>[washerPage, drierPage],
              ),
            ),
          );
        } else if (drierPage != null) {
          return drierPage;
        }

        return washerPage;
      },
    );
  }
}

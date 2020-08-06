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
import 'package:laundryqueue/services/storage.dart';

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
            title: 'Washing',
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
                hideAppBar: hasDrierQueueData,
                toggle: _toggle,
                queuedUnderOtherUser: washerQueueData.queuedUnderOtherUser,
              )
            : null;

    drierPage = _queueInProgress(userDrierQueueInstance)
        ? QueueInProgress(
            userQueueInstance: userDrierQueueInstance,
            title: 'Drying',
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
                hideAppBar: hasWasherQueueData,
                machineType: widget.drierQueueData.whichMachine,
                queuedUnderOtherUser: drierQueueData.queuedUnderOtherUser,
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
    if (washerQueueData != oldWidget.washerQueueData ||
        drierQueueData != oldWidget.drierQueueData) {
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
                bottom: TabBar(
                  indicatorColor: Colors.blueGrey,
                  labelPadding: EdgeInsets.all(8),
                  indicatorPadding: EdgeInsets.symmetric(horizontal: 32),
                  tabs: <Widget>[
                    Icon(
                      Icons.fiber_smart_record,
                      color: Colors.blueGrey[700],
                    ),
                    Icon(
                      Icons.wb_sunny,
                      color: Colors.blueGrey[700],
                    ),
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

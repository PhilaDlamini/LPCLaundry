import 'package:flutter/material.dart';
import 'package:laundryqueue/inherited_widgets/user_inherited_widget.dart';
import 'package:laundryqueue/models/Queue.dart';
import 'package:laundryqueue/models/QueueData.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/home/pages/queue_in_progress.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/widgets/queued_list_base.dart';

class QueuedList extends StatefulWidget {
  final QueueData washerQueueData;
  final QueueData drierQueueData;

  QueuedList({this.washerQueueData, this.drierQueueData});

  @override
  State<StatefulWidget> createState() => _QueuedListState();
}

class _QueuedListState extends State<QueuedList> {
  int currentPage = 0;
  User user;
  Widget washerPage;
  Widget drierPage;
  Queue userDrierQueueInstance;
  Queue userWasherQueueInstance;

  bool _queueInProgress(Queue queue) {
    if (queue == null) {
      return false;
    }

    DateTime startTime =
        DateTime.fromMillisecondsSinceEpoch(queue.startTimeInMillis);
    return startTime.isBefore(DateTime.now());
  }

  void _initialize() async {
    bool hasWasherQueueData = widget.washerQueueData != null;
    bool hasDrierQueueData = widget.drierQueueData != null;

    userWasherQueueInstance = (hasWasherQueueData)
        ? widget.washerQueueData.queueInstances
            .singleWhere((queue) => queue.user.uid == user.uid)
        : null;

    userDrierQueueInstance = (hasDrierQueueData)
        ? widget.drierQueueData.queueInstances
            .singleWhere((queue) => queue.user.uid == user.uid)
        : null;

    //Initialize the pages
    washerPage = _queueInProgress(userWasherQueueInstance)
        ? QueueInProgress(
            queue: userWasherQueueInstance,
            title: 'Washing in progress',
            whichQueue: 'washer queue',
            machineNumber: widget.washerQueueData.machineNumber,
          )
        : hasWasherQueueData
            ? QueueListBase(
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
            queue: userDrierQueueInstance,
            title: 'Drying in progress',
            whichQueue: 'drier queue',
            machineNumber: widget.drierQueueData.machineNumber,
          )
        : hasDrierQueueData
            ? QueueListBase(
                usersInQueue: widget.drierQueueData.queueInstances,
                userQueueInstance: userDrierQueueInstance,
                machineNumber: widget.drierQueueData.machineNumber,
                enableQueuing: !hasDrierQueueData,
                machineType: widget.drierQueueData.whichMachine,
                toggle: _toggle,
              )
            : null;
  }

  void _toggle() {
    setState(() {}); //Redraws
  }

  @override
  Widget build(BuildContext context) {
    user = UserInheritedWidget.of(context).user;

    _initialize();

    //We display whatever list is not null
    if (washerPage != null && drierPage != null) {
      List<Widget> pages = [washerPage, drierPage];

      return Scaffold(
        body: pages[currentPage],
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.wb_iridescent), title: Text('Washer')),
            BottomNavigationBarItem(
                icon: Icon(Icons.wb_sunny), title: Text('Drier')),
          ],
          currentIndex: currentPage,
          onTap: (index) {
            setState(() => currentPage = index);
          },
        ),
      );
    } else if (drierPage != null) {
      return drierPage;
    }

    return washerPage;
  }
}

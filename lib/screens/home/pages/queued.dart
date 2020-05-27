import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/data_handler_models/QueueData.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/home/pages/queue_in_progress.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/widgets/queued_list_base.dart';

class Queued extends StatefulWidget {
  final QueueData washerQueueData;
  final QueueData drierQueueData;

  Queued({this.washerQueueData, this.drierQueueData});

  @override
  State<StatefulWidget> createState() => _QueuedState();
}

class _QueuedState extends State<Queued> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  int _currentPage = 0;
  User user;
  Widget washerPage;
  Widget drierPage;
  QueueInstance userDrierQueueInstance;
  QueueInstance userWasherQueueInstance;
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
    hasWasherQueueData = widget.washerQueueData != null;
    hasDrierQueueData = widget.drierQueueData != null;

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
            userQueueInstance: userWasherQueueInstance,
            title: 'Washing in progress',
            whichQueue: 'washer queue',
            machineNumber: widget.washerQueueData.machineNumber,
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
            machineNumber: widget.drierQueueData.machineNumber,
          )
        : hasDrierQueueData
            ? QueueListBase(
                whichQueue: 'drier queue',
                usersInQueue: widget.drierQueueData.queueInstances,
                userQueueInstance: userDrierQueueInstance,
                machineNumber: widget.drierQueueData.machineNumber,
                enableQueuing: !hasDrierQueueData,
                machineType: widget.drierQueueData.whichMachine,
                toggle: _toggle,
              )
            : null;

    _scheduleNotifications();

    return 'Done';
  }

  /*
    If the user queues for only the washer/drier individually, the notification isn't deleted as when data changes we don't come here
    If they queue for both the washer and drier, when washer finishes the notification is deleted and only the drier one will remain
  * */
  void _scheduleNotifications() async {
    bool isNotifyingOnTurn =
        await Preferences.getBoolData(Preferences.NOTIFY_ON_TURN);
    bool isNotifyingWhenDone =
        await Preferences.getBoolData(Preferences.NOTIFY_WHEN_DONE);

    //First, remove any notifications that might have been scheduled before for this user
    if (isNotifyingOnTurn) {
      await _notificationsPlugin.cancel(WASHER_NOTIFY_ON_TURN_ID);
      await _notificationsPlugin.cancel(DRIER_NOTIFY_ON_TURN_ID);
    }

    if (isNotifyingWhenDone) {
      await _notificationsPlugin.cancel(WASHER_NOTIFY_WHEN_DONE_ID);
      await _notificationsPlugin.cancel(DRIER_NOTIFY_WHEN_DONE_ID);
    }

    //Schedule the new notifications
    NotificationDetails notificationDetails = NotificationDetails(
        AndroidNotificationDetails(
            CHANNEL_ID, CHANNEL_NAME, CHANNEL_DESCRIPTION,
            styleInformation: BigTextStyleInformation('')),
        IOSNotificationDetails());

    if (hasWasherQueueData) {
      if (isNotifyingOnTurn) {
        DateTime fiveMinutesEarlier = DateTime.fromMillisecondsSinceEpoch(
                userWasherQueueInstance.startTimeInMillis)
            .subtract(Duration(minutes: 5));
        if (fiveMinutesEarlier.isBefore(DateTime.now()) ||
            fiveMinutesEarlier.isAtSameMomentAs(DateTime.now())) {
          _notificationsPlugin.show(
              WASHER_NOTIFY_ON_TURN_ID,
              'Your turn is close',
              'Your turn to use the washing machine starts at ${userWasherQueueInstance.displayableTime['startTime']}',
              notificationDetails);
        } else {
          _notificationsPlugin.schedule(
              WASHER_NOTIFY_ON_TURN_ID,
              'Your turn is close',
              'Your turn to use the washing machine starts at ${userWasherQueueInstance.displayableTime['startTime']}',
              fiveMinutesEarlier,
              notificationDetails);
        }
      }

      if (isNotifyingWhenDone) {
        _notificationsPlugin.schedule(
            WASHER_NOTIFY_WHEN_DONE_ID,
            'You clothes are done washing',
            'Your clothes finished washing at ${userWasherQueueInstance.displayableTime['endTime']}',
            DateTime.fromMillisecondsSinceEpoch(
                userWasherQueueInstance.endTimeInMillis),
            notificationDetails);
      }
    }

    //Repeat the same for the drier data
    if (hasDrierQueueData) {
      if (isNotifyingOnTurn) {
        DateTime fiveMinutesEarlier = DateTime.fromMillisecondsSinceEpoch(
                userDrierQueueInstance.startTimeInMillis)
            .subtract(Duration(minutes: 5));
        if (fiveMinutesEarlier.isBefore(DateTime.now()) ||
            fiveMinutesEarlier.isAtSameMomentAs(DateTime.now())) {
          _notificationsPlugin.show(
              DRIER_NOTIFY_ON_TURN_ID,
              'Your turn is close',
              'Your turn to use the drier starts at ${userDrierQueueInstance.displayableTime['startTime']}',
              notificationDetails);
        } else {
          _notificationsPlugin.schedule(
              DRIER_NOTIFY_ON_TURN_ID,
              'Your turn is close',
              'Your turn to use the drier starts at ${userDrierQueueInstance.displayableTime['starTime']}',
              fiveMinutesEarlier,
              notificationDetails);
        }
      }

      if (isNotifyingWhenDone) {
        _notificationsPlugin.schedule(
            DRIER_NOTIFY_WHEN_DONE_ID,
            'You clothes are done drying',
            'Your clothes finished drying at ${userDrierQueueInstance.displayableTime['endTime']}',
            DateTime.fromMillisecondsSinceEpoch(
                userDrierQueueInstance.endTimeInMillis),
            notificationDetails);
      }
    }
  }

  void _toggle() {
    setState(() {}); //Redraws
  }

  @override
  void initState() {
    _notificationsPlugin.initialize(
        InitializationSettings(
            AndroidInitializationSettings('@mipmap/ic_launcher'),
            IOSInitializationSettings()),
        onSelectNotification: (payload) async {
      await Navigator.pushNamed(context, '/home');
    });
    super.initState();
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
          return Scaffold(
            body: IndexedStack(
              index: _currentPage,
              children: <Widget>[washerPage, drierPage],
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                    icon: Icon(Icons.wb_iridescent), title: Text('Washer')),
                BottomNavigationBarItem(
                    icon: Icon(Icons.wb_sunny), title: Text('Drier')),
              ],
              currentIndex: _currentPage,
              onTap: (index) {
                setState(() => _currentPage = index);
              },
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

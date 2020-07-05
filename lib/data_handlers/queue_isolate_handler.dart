import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/queue_isolate.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class QueueIsolateHandler {
  final List<QueueData> queueDataList;
  final User user;
  BuildContext context;
  QueueIsolate _washerSkipUserIsolate;
  QueueIsolate _washerFinishQueueIsolate;
  QueueIsolate _drierSkipUserIsolate;
  QueueIsolate _drierFinishQueueIsolate;
  QueueInstance lastWasherQueueInstance;
  QueueInstance lastDrierQueueInstance;
  QueueInstance userWasherQueueInstance;
  QueueInstance userDrierQueueInstance;
  QueueData washerQueueData;
  QueueData drierQueueData;
  bool machineUseConfirmed;
  bool washerQueueRemoved;
  bool drierQueueRemoved;
  bool washerExtensionGranted;
  bool drierExtensionGranted;
  bool hasWasherQueueData;
  bool hasDrierQueueData;

  FlutterLocalNotificationsPlugin _notificationsPlugin;

  QueueIsolateHandler(this.context, {this.queueDataList, this.user}) {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    _notificationsPlugin.initialize(
        InitializationSettings(
            AndroidInitializationSettings('@mipmap/ic_launcher'),
            IOSInitializationSettings()),
        onSelectNotification: (payload) async {
          await Navigator.pushNamed(context, '/home');
        });
  }

  void _initialize() {

    washerQueueData = queueDataList.singleWhere(
            (item) => item.whichMachine == 'washer' && item.userQueued,
        orElse: () => null);
    drierQueueData = queueDataList.singleWhere(
            (item) => item.whichMachine == 'drier' && item.userQueued,
        orElse: () => null);

    //Initialize the rest of the variables
    hasWasherQueueData = washerQueueData != null;
    hasDrierQueueData = drierQueueData != null;

    if(hasWasherQueueData) {
      if(washerQueueData.queuedUnderOtherUser) {
        userWasherQueueInstance = washerQueueData.queueInstanceUnder;
      } else {
        userWasherQueueInstance = washerQueueData.queueInstances.singleWhere((instance) => instance.user.uid == user.uid);
      }
    }

    if(hasDrierQueueData) {
      if(drierQueueData.queuedUnderOtherUser) {
        userDrierQueueInstance = drierQueueData.queueInstanceUnder;
      } else {
        userDrierQueueInstance = drierQueueData.queueInstances.singleWhere((instance) => instance.user.uid == user.uid);
      }
    }
  }

  void startIsolates() async {

    //Initialize all variables
    _initialize();

    if (hasWasherQueueData && !washerQueueData.queuedUnderOtherUser) {
      //Get the most recent queue instance from shared preferences
      lastWasherQueueInstance = await _getRecentQueueInstance(
          Preferences.RECENT_USER_WASHER_QUEUE_INSTANCE);

      if (userWasherQueueInstance != lastWasherQueueInstance) {
        //The data received is different from the last. Update the recent washer queue instance and start the isolates
        lastWasherQueueInstance =
            QueueInstance.fromMap(userWasherQueueInstance.toQueuingMap());
        _updateRecentQueueInstance(
            Preferences.RECENT_USER_WASHER_QUEUE_INSTANCE,
            userWasherQueueInstance); //Updates the lastWasherQueueInstance
        _startWasherIsolates(userWasherQueueInstance, washerQueueData);
      }
    }

    //Spawn the isolates to skip the user / finish their queue
    if (hasDrierQueueData && !drierQueueData.queuedUnderOtherUser) {
      //Get the the most recent one from shared preferences
      lastDrierQueueInstance =
          await _getRecentQueueInstance(Preferences.RECENT_USER_DRIER_QUEUE_INSTANCE);

      if (userDrierQueueInstance != lastDrierQueueInstance) {
        //The data received is different from the last. Update the most recent drier queue instance and start the isolates
        lastDrierQueueInstance = userDrierQueueInstance; //Update the last instance
        _updateRecentQueueInstance(
            Preferences.RECENT_USER_DRIER_QUEUE_INSTANCE, userDrierQueueInstance);
        _startDrierIsolates(userDrierQueueInstance, drierQueueData);
      }
    }

    //Schedule all necessary notifications
    _scheduleNotifications();
  }

  ///Starts the washer isolates
  void _startWasherIsolates(QueueInstance washerQueueInstance, QueueData washerQueueData) {

    _washerSkipUserIsolate = QueueIsolate(
      duration:
          washerQueueInstance.timeLeftTillQueueStart + Duration(seconds: 60),
      onFinished: () async {
        //Re-read in case the machine use was recently confirmed
        await _isMachineUseConfirmed(Preferences.WASHER_USE_CONFIRMED);

        //Lastly, check if this queue was not removed (either through un-queuing or by granting an extension
        await _checkIfRemoved();

        if (!machineUseConfirmed) {
          //Only skip this queue if it was not removed already
          if (!washerQueueRemoved) {
            //Skip the user
            DatabaseService(
                    whichQueue: 'washer queue',
                    machineNumber: washerQueueData.machineNumber,
                    location: 'Block ${washerQueueInstance.user.block}')
                .skipUser(washerQueueInstance, queueDataList)
                .then((onValue) => print('The user is skipped!'));
          } else {

            //Reset
            await Preferences.updateBoolData(
                Preferences.WASHER_QUEUE_REMOVED_AT_TIME, false);
          }

          //Stop the finishQueue isolate as this user has been skipped
          _washerFinishQueueIsolate.stop();
        }

        //We are done waiting, stop this isolate
        _washerSkipUserIsolate.stop();
      },
    );

    _washerFinishQueueIsolate = QueueIsolate(
        duration: washerQueueInstance.timeLeftTillQueueEnd,
        onFinished: () async {

          await _checkIfRemoved();
          await _checkIfExtensionsGranted();

          //Re-set confirmation and finish the queue if an extension was not granted
          if(!washerExtensionGranted) {
            await resetMachineConfirmation(Preferences.WASHER_USE_CONFIRMED);
          } else {
            await Preferences.updateBoolData(Preferences.WASHER_QUEUE_EXTENSION_GRANTED, false);
          }

          if(!washerQueueRemoved) {
            DatabaseService(
                whichQueue: 'washer queue',
                location: 'Block ${washerQueueInstance.user.block}',
                machineNumber: washerQueueData.machineNumber)
                .finishQueue(queue: washerQueueInstance, queueDataList: queueDataList);
          } else {
            await Preferences.updateBoolData(Preferences.WASHER_QUEUE_REMOVED_AT_TIME, false);
          }

          //Stop the washerFinishQueue isolate (where the user not skipped)
          _washerFinishQueueIsolate.stop();
        });


    //Start both isolates
    _washerSkipUserIsolate.start();
    _washerFinishQueueIsolate.start();
  }

  /// Starts the drier isolates
  void _startDrierIsolates(QueueInstance drierQueueInstance, QueueData drierQueueData) {

    _drierSkipUserIsolate = QueueIsolate(
      duration:
          drierQueueInstance.timeLeftTillQueueStart + Duration(seconds: 60),
      onFinished: () async {
        await _isMachineUseConfirmed(Preferences.DRIER_USE_CONFIRMED);
        await _checkIfRemoved();

        if (!machineUseConfirmed) {
          if (!drierQueueRemoved) {
            DatabaseService(
                    whichQueue: 'drier queue',
                    machineNumber: drierQueueData.machineNumber,
                    location: 'Block ${drierQueueInstance.user.block}')
                .skipUser(drierQueueInstance, queueDataList)
                .then((onValue) => print('The user is skipped!'));
          } else {
            await Preferences.updateBoolData(
                Preferences.DRIER_QUEUE_REMOVED_AT_TIME, false);
            }
          _drierFinishQueueIsolate.stop();
        }
        _drierSkipUserIsolate.stop();
      },
    );

    _drierFinishQueueIsolate = QueueIsolate(
        duration: drierQueueInstance.timeLeftTillQueueEnd,
        onFinished: () async {

          await _checkIfExtensionsGranted();
          await _checkIfRemoved();

          //Re-set confirmation if the user was not granted an extension and they are done using the machine
          if(!drierExtensionGranted) {
            await resetMachineConfirmation(Preferences.DRIER_USE_CONFIRMED);
          } else {
            await Preferences.updateBoolData(Preferences.DRIER_QUEUE_EXTENSION_GRANTED, false);
          }

          if(!drierQueueRemoved) {
            DatabaseService(
                whichQueue: 'drier queue',
                location: 'Block ${drierQueueInstance.user.block}',
                machineNumber: drierQueueData.machineNumber)
                .finishQueue(queue: drierQueueInstance);
          } else {
            await Preferences.updateBoolData(Preferences.DRIER_QUEUE_REMOVED_AT_TIME, false);
          }

          //We are done waiting. Finish this isolate
          _drierFinishQueueIsolate.stop();
        });

    //Start both isolates
    _drierSkipUserIsolate.start();
    _drierFinishQueueIsolate.start();
  }

  void _scheduleNotifications() async {
    bool isNotifyingOnTurn =
    await Preferences.getBoolData(Preferences.NOTIFY_ON_TURN);
    bool isNotifyingWhenDone =
    await Preferences.getBoolData(Preferences.NOTIFY_WHEN_DONE);
    bool isNotifyingWhenQueuedJointly =
    await Preferences.getBoolData(Preferences.NOTIFY_WHEN_QUEUED_JOINTLY);

    //First, remove any notifications that might have been scheduled before for this user
    if (isNotifyingOnTurn) {
      await _notificationsPlugin.cancel(WASHER_NOTIFY_ON_TURN_ID);
      await _notificationsPlugin.cancel(DRIER_NOTIFY_ON_TURN_ID);
    }

    if (isNotifyingWhenDone) {
      await _notificationsPlugin.cancel(WASHER_NOTIFY_WHEN_DONE_ID);
      await _notificationsPlugin.cancel(DRIER_NOTIFY_WHEN_DONE_ID);
    }

    if(isNotifyingWhenQueuedJointly) {
      await _notificationsPlugin.cancel(QUEUED_JOINTLY_IN_DRIER);
      await _notificationsPlugin.cancel(QUEUED_JOINTLY_IN_WASHER);
    }

    //Schedule the new notifications
    NotificationDetails notificationDetails = NotificationDetails(
        AndroidNotificationDetails(
            CHANNEL_ID, CHANNEL_NAME, CHANNEL_DESCRIPTION,
         //   sound: 'juntos', //For some reason it will not accept the string
            priority: Priority.High,
            importance: Importance.Max,
            styleInformation: BigTextStyleInformation(''),
        ),
        IOSNotificationDetails(sound: 'juntos.aiff')
    );

    if (hasWasherQueueData) {
      String correctPhrase = await getCorrectPhrase(userWasherQueueInstance);

      if (isNotifyingOnTurn) {
        DateTime fiveMinutesEarlier = DateTime.fromMillisecondsSinceEpoch(
            userWasherQueueInstance.startTimeInMillis)
            .subtract(Duration(minutes: 5));

        if (fiveMinutesEarlier.isBefore(DateTime.now()) ||
            fiveMinutesEarlier.isAtSameMomentAs(DateTime.now())) {
          _notificationsPlugin.show(
              WASHER_NOTIFY_ON_TURN_ID,
              'Your turn is close',
              '$correctPhrase turn to use the washing machine starts at ${userWasherQueueInstance.displayableTime['startTime']}',
              notificationDetails);
        } else {
          _notificationsPlugin.schedule(
              WASHER_NOTIFY_ON_TURN_ID,
              'Your turn is close',
              '$correctPhrase turn to use the washing machine starts at ${userWasherQueueInstance.displayableTime['startTime']}',
              fiveMinutesEarlier,
              notificationDetails);
        }
      }

      if (isNotifyingWhenDone) {

        String correctPhrase = await getCorrectPhrase(userWasherQueueInstance);
        _notificationsPlugin.schedule(
            WASHER_NOTIFY_WHEN_DONE_ID,
            'You clothes are done washing',
            '$correctPhrase clothes finished washing at ${userWasherQueueInstance.displayableTime['endTime']}',
            DateTime.fromMillisecondsSinceEpoch(
                userWasherQueueInstance.endTimeInMillis),
            notificationDetails);

      }
    }
    //Repeat the same for the drier data
    if (hasDrierQueueData) {
      String correctPhrase = await getCorrectPhrase(userDrierQueueInstance);

      if (isNotifyingOnTurn) {
        DateTime fiveMinutesEarlier = DateTime.fromMillisecondsSinceEpoch(
            userDrierQueueInstance.startTimeInMillis)
            .subtract(Duration(minutes: 5));
        if (fiveMinutesEarlier.isBefore(DateTime.now()) ||
            fiveMinutesEarlier.isAtSameMomentAs(DateTime.now())) {
          _notificationsPlugin.show(
              DRIER_NOTIFY_ON_TURN_ID,
              'Your turn is close',
              '$correctPhrase turn to use the drier starts at ${userDrierQueueInstance.displayableTime['startTime']}',
              notificationDetails);
        } else {
          _notificationsPlugin.schedule(
              DRIER_NOTIFY_ON_TURN_ID,
              'Your turn is close',
              '$correctPhrase turn to use the drier starts at ${userDrierQueueInstance.displayableTime['starTime']}',
              fiveMinutesEarlier,
              notificationDetails);
        }
      }

      if (isNotifyingWhenDone) {
        String correctPhrase = await getCorrectPhrase(userDrierQueueInstance);

        _notificationsPlugin.schedule(
            DRIER_NOTIFY_WHEN_DONE_ID,
            'You clothes are done drying',
            '$correctPhrase clothes finished drying at ${userDrierQueueInstance.displayableTime['endTime']}',
            DateTime.fromMillisecondsSinceEpoch(
                userDrierQueueInstance.endTimeInMillis),
            notificationDetails);
      }
    }

    if(hasWasherQueueData && washerQueueData.queuedUnderOtherUser) {
      if (isNotifyingWhenQueuedJointly) {
        _notificationsPlugin.show(
            QUEUED_JOINTLY_IN_WASHER,
            'You are washing with ${userWasherQueueInstance.user.name}',
            '${userWasherQueueInstance.user
                .name} has queued to wash their clothes with you.'
                ' Your turn starts at ${userWasherQueueInstance
                .displayableTime['startTime']}',
            notificationDetails);
      }
    }

    if(hasDrierQueueData && drierQueueData.queuedUnderOtherUser) {
      if (isNotifyingWhenQueuedJointly) {
        _notificationsPlugin.show(
            QUEUED_JOINTLY_IN_DRIER,
            'You are drying with ${userDrierQueueInstance.user.name}',
            '${userDrierQueueInstance.user
                .name} has queued to dry their clothes with you.'
                ' Your turn starts at ${userDrierQueueInstance
                .displayableTime['startTime']}',
            notificationDetails);
      }
    }
  }

  Future<String> getCorrectPhrase(QueueInstance instance) async {
    String correctPhrase;
    if(instance.isQueuedJointly) {
      String others = await instance.namesOfUsersQueuedWith;
      correctPhrase = '$others and ${instance.user.name}: your';
    } else {
      correctPhrase = 'Your';
    }
    return correctPhrase;
  }

  ///Gets if the queue(s) were removed or not
  Future _checkIfRemoved() async {
    washerQueueRemoved =
        await Preferences.getBoolData(Preferences.WASHER_QUEUE_REMOVED_AT_TIME);
    drierQueueRemoved =
        await Preferences.getBoolData(Preferences.DRIER_QUEUE_REMOVED_AT_TIME);
  }

  ///Gets if the extensions were granted for queue
  Future _checkIfExtensionsGranted() async {
    washerExtensionGranted = await Preferences.getBoolData(Preferences.WASHER_QUEUE_EXTENSION_GRANTED);
    drierExtensionGranted = await Preferences.getBoolData(Preferences.DRIER_QUEUE_EXTENSION_GRANTED);
  }

  ///Gets if the machine use is confirmed.
  Future _isMachineUseConfirmed(String key) async {
    machineUseConfirmed = await Preferences.getBoolData(key);
  }

  Future<QueueInstance> _getRecentQueueInstance(String key) async {
    String queueInstance = await Preferences.getStringData(key);

    if (queueInstance != null) {
      return QueueInstance.fromMap(json.decode(queueInstance));
    }

    return QueueInstance();
  }

  ///Updates the last queue instance saved to be the most recent one
  Future _updateRecentQueueInstance(
      String key, QueueInstance queueInstance) async {
    await Preferences.updateStringData(
        key, json.encode(queueInstance.toQueuingMap()));
  }
}

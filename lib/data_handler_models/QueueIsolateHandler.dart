import 'dart:convert';
import 'package:laundryqueue/data_handler_models/QueueData.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/queue_isolate.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class QueueIsolateHandler {
  final List<QueueData> queueDataList;
  final User user;
  QueueIsolate _washerSkipUserIsolate;
  QueueIsolate _washerFinishQueueIsolate;
  QueueIsolate _drierSkipUserIsolate;
  QueueIsolate _drierFinishQueueIsolate;
  QueueInstance lastWasherQueueInstance;
  QueueInstance lastDrierQueueInstance;
  bool machineUseConfirmed;

  QueueIsolateHandler({this.queueDataList, this.user});

  void startIsolates() async {

    //Get the queueData instances where the user is queued
    QueueData washerQueueData = queueDataList.singleWhere(
            (item) => item.whichMachine == 'washer' && item.userQueued,
        orElse: () => null);
    QueueData drierQueueData = queueDataList.singleWhere(
            (item) => item.whichMachine == 'drier' && item.userQueued,
        orElse: () => null);

    if(washerQueueData != null) {

      //Get the sent washer queue instance as well as most recent one from shared preferences
      QueueInstance washerQueueInstance = washerQueueData.queueInstances
          .singleWhere((queue) => queue.user.uid == user.uid);
      lastWasherQueueInstance = await _getQueueInstance(Preferences.RECENT_USER_WASHER_QUEUE_INSTANCE);

      if(washerQueueInstance != lastWasherQueueInstance) {
        //The data received is different from the last. Update the most recent washer queue instance and start the isolates
        lastWasherQueueInstance = QueueInstance.fromMap(washerQueueInstance.toQueuingMap());
        _updateRecentQueueInstance(Preferences.RECENT_USER_WASHER_QUEUE_INSTANCE, washerQueueInstance);//Updates the lastWasherQueueInstance
        _startWasherIsolates(washerQueueInstance, washerQueueData);
      }

    }

    //Spawn the isolates to skip the user / finish their queue
    if(drierQueueData != null) {

      //Get the sent drier queue instance as well as the most recent one from shared preferences
      QueueInstance drierQueueInstance = drierQueueData.queueInstances
          .singleWhere((queue) => queue.user.uid == user.uid);
      lastDrierQueueInstance = await _getQueueInstance(Preferences.RECENT_USER_DRIER_QUEUE_INSTANCE);

      if(drierQueueInstance != lastDrierQueueInstance) {
        //The data received is different from the last. Update the most recent drier queue instance and start the isolates
        lastDrierQueueInstance = drierQueueInstance; //Update the last instance
        _updateRecentQueueInstance(Preferences.RECENT_USER_DRIER_QUEUE_INSTANCE, drierQueueInstance);
        _startDrierIsolates(drierQueueInstance, drierQueueData);
      }

    }

  }

  ///Starts the washer isolates
  void _startWasherIsolates(QueueInstance washerQueueInstance, QueueData washerQueueData) {

    _washerSkipUserIsolate = QueueIsolate(
      duration: washerQueueInstance.timeLeftTillQueueStart + Duration(seconds: 60),
      onFinished: () async {

        //Re-read in case the machine use was recently confirmed
        await _isMachineUseConfirmed(Preferences.WASHER_USE_CONFIRMED);

        if (!machineUseConfirmed) {

          //Skip the user
          DatabaseService(
              whichQueue: 'washer queue',
              machineNumber: washerQueueData.machineNumber,
              location: 'Block ${washerQueueInstance.user.block}')
              .skipUser(washerQueueInstance, queueDataList)
              .then((onValue) => print('The user is skipped!'));

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

          //Re-set confirmation and finish the queue for this user
          await _resetMachineConfirmation(Preferences.WASHER_USE_CONFIRMED);

          DatabaseService(
              whichQueue: 'washer queue',
              location: 'Block ${washerQueueInstance.user.block}',
              machineNumber: washerQueueData.machineNumber)
              .finishQueue(queue: washerQueueInstance);

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
      duration: drierQueueInstance.timeLeftTillQueueStart + Duration(seconds: 60),
      onFinished: () async {

        await _isMachineUseConfirmed(Preferences.DRIER_USE_CONFIRMED);

        if (!machineUseConfirmed) {

          DatabaseService(
              whichQueue: 'drier queue',
              machineNumber: drierQueueData.machineNumber,
              location: 'Block ${drierQueueInstance.user.block}')
              .skipUser(drierQueueInstance, queueDataList)
              .then((onValue) => print('The user is skipped!'));

          _drierFinishQueueIsolate.stop();
        }

        _drierSkipUserIsolate.stop();
      },
    );

    _drierFinishQueueIsolate = QueueIsolate(
        duration: drierQueueInstance.timeLeftTillQueueEnd,
        onFinished: () async {

          //Re-set confirmation and finish the queue for this user
          await _resetMachineConfirmation(Preferences.DRIER_USE_CONFIRMED);

          DatabaseService(
              whichQueue: 'drier queue',
              location: 'Block ${drierQueueInstance.user.block}',
              machineNumber: drierQueueData.machineNumber)
              .finishQueue(queue: drierQueueInstance);

          //We are done waiting. Finish this isolate
          _washerFinishQueueIsolate.stop();
        });

    //Start both isolates
    _drierSkipUserIsolate.start();
    _drierFinishQueueIsolate.start();
  }

  ///Gets if the machine use is confirmed.
  Future _isMachineUseConfirmed(String key) async {
    machineUseConfirmed = await Preferences.getBoolData(key);
  }

  ///Resets machine confirmation
  Future _resetMachineConfirmation(String key) async {
    await Preferences.updateBoolData(key, false);
  }

  ///Updates the last queue instance saved to be the most recent one
  Future _updateRecentQueueInstance(String key, QueueInstance queueInstance) async {
    await Preferences.updateStringData(key, json.encode(queueInstance.toQueuingMap()));
  }

  ///Returns the recent queue instance from shared preferences
  Future<QueueInstance> _getQueueInstance(String key) async {
    String queueInstance = await Preferences.getStringData(key);

    if(queueInstance != null) {
      return QueueInstance.fromMap(json.decode(queueInstance));
    }

    return QueueInstance();
  }

}
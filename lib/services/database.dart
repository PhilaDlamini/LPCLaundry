import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class DatabaseService {
  static final Firestore _fireStore = Firestore.instance;
  final CollectionReference _users = _fireStore.collection('all users');
  final List<String> availableWashers;
  final List<String> availableDriers;
  final User user;
  final String uid;
  final String location;
  final String whichQueue;
  final String machineNumber;

  DatabaseService({this.uid,
      this.user,
      this.availableDriers,
      this.availableWashers,
      this.location,
      this.machineNumber,
      this.whichQueue});

  Stream<QuerySnapshot> get usersStream => _users.snapshots();

  //Updates user information in the database
  Future<dynamic> setUserInfo() async => await _users.document(user.uid).setData(user.toMap());

  //Updates the user information
  Future updateUserInfo(Map<String, dynamic> data, {User passedUser}) async => await _users.document(passedUser != null ?
   passedUser.uid : user.uid).updateData(data);

  //Removes the user information from the database
  Future removeUserInfo() async => await _users.document(user.uid).delete();

  // Gets the user data for this uid
  Future<User> getUser() async {
    DocumentSnapshot snapshot = await _users.document(uid).get();
    return User.fromMap(snapshot.data);
  }

  //Returns the a list of the users in the same block as this one
  Future getUsersInBlock() async{

    //Holds the list of users
    List<User> users = List<User>();

    //Get the documents and loop through them
    QuerySnapshot querySnapshots = await _fireStore.collection('all users').getDocuments();

    for(DocumentSnapshot snapshot in querySnapshots.documents) {
      User currentUser = User.fromMap(snapshot.data);
      if(currentUser != user && currentUser.block == user.block && !currentUser.currentlyQueued) {
        users.add(currentUser);
      }
    }
    return users.isEmpty ? 'No other people in block ${user.block}' : users;
  }

  //Updates the machine availability
  Future updateMachineAvailability(String whichQueue, Map<String, List<bool>> data) async =>
      await _fireStore.collection(whichQueue).document('Block ${user.block}').updateData(data);

  //Flushes all the in the queue after a machine has been disabled
  Future flushAllInQueue() async {
    //TODO: Implement this method
    return null;
  }

  //Queues the user for the specified machine at the specified location
  Future<dynamic> queue(QueueInstance queue) async {
    DocumentReference queuedListReference = _fireStore
        .collection(whichQueue)
        .document(queue.location)
        .collection(queue.which)
        .document('queued list');
    DocumentSnapshot snapshot = await queuedListReference.get();

    //If the data is null, this is the first time a user is queuing up. Just save the queue instance
    if (snapshot.data == null) {
      queuedListReference.setData({
        'queue': [
          queue.toQueuingMap(),
        ]
      });
    } else {
      //Otherwise, re-read all the data and save it
      List<dynamic> queueList = snapshot.data['queue'];
      queueList.add(queue.toQueuingMap());

      //Make sure they are sorted by start times (sooner times first)
      queueList.sort((a, b) => a['startTime'].compareTo(b['startTime']));
      queuedListReference.setData({'queue': queueList});
    }
  }

  //Un-queues the user when they are done using the machine
  Future finishQueue({QueueInstance queue, List<QueueData> queueDataList}) async {
    //Get the data from the queue
    DocumentReference reference = _fireStore
        .collection(whichQueue)
        .document(location)
        .collection(machineNumber)
        .document('queued list');
    DocumentSnapshot snapshot = await reference.get();

    //Remove the user from the list
    List<dynamic> usersQueued = snapshot.data['queue'];
    Map<String, dynamic> userQueueInstance = usersQueued.singleWhere((item) => item['user']['uid'].trim() == queue.user.uid);
    usersQueued.remove(userQueueInstance);

    //Save the queue data to preferences (for the summary later)
    String key = whichQueue == 'washer queue' ? Preferences.LAST_WASHER_USED_DATA : Preferences.LAST_DRIER_USED_DATA;
    String jsonData = json.encode(queue.toSummaryMap(machineNumber));
    print('summary data to save: $jsonData');
    await Preferences.updateStringData(key, jsonData);
    print('Should have saved this data now');

    //If this is the washer queue, check to see if the user also queued for the drier. If not, reset queue status. Else, wait
    List<String> uIDs = queue.usersQueuedWith;
    uIDs.add(queue.user.uid);

    if(whichQueue == 'washer queue') {
      for(String uid in uIDs) {
        bool queuedInDrier = _isAlsoQueuedInDrier(uid, queueDataList);
        if(!queuedInDrier) {
          await updateUserInfo({'currentlyQueued' : false}, passedUser: User(uid: uid));
        }
      }
    } else {
      for(String uid in uIDs) {
       await updateUserInfo({'currentlyQueued' : false}, passedUser: User(uid: uid));
      }
    }

    //Re-save the data
    await reference.setData({
      'queue': usersQueued,
    });

    return 'Done';
  }

  ///Grants the given queue the specified extension
  ///Before this, a user will have to get approval from five of those in the queue
  Future grantExtension({QueueInstance queueInstance, int timeExtensionInMillis, List<QueueData> queueDataList}) async {

    //Holds information about which driers's times need to be updated if this were a washer queue
    //The map is in the form of key: machine number, value: lowest index value to update
    Map<String, int> infoAboutDriersToUpdate = Map<String, int>();

    //Read the data and update and end times
    DocumentReference _reference = _fireStore.collection(whichQueue).document(location).collection(machineNumber).document('queued list');
    DocumentSnapshot snapshot = await _reference.get();
    List<dynamic> queueInstances = snapshot.data['queue'];
    var userQueueInstance = queueInstances.singleWhere((instance) => instance['user']['uid'] == queueInstance.user.uid);

    //Holds the updated queue instances
    List<dynamic> updatedQueueInstances = List<dynamic>();

    for(var washerQueueInstance in queueInstances) {

      //Collect information about where this user is also queued in the driers if this is the washer queue
      if(whichQueue == 'washer queue') {

        Map<String, dynamic> userQueueData = _isQueuedInBothWasherAndDrier(washerQueueInstance, queueDataList);

        if(userQueueData['queuedInBoth']) {
          String machineNumber = userQueueData['drierMachineNumber'];
          int newIndex = userQueueData['indexInList'];

          if(infoAboutDriersToUpdate.containsKey(machineNumber)) {
            int recordedIndex = infoAboutDriersToUpdate[machineNumber];
            if(newIndex < recordedIndex) {
              infoAboutDriersToUpdate[machineNumber] =  newIndex;
            }
          } else {
            infoAboutDriersToUpdate[machineNumber] =  newIndex;
          }
        }

      }

      //Update the start and end times
      washerQueueInstance['endTime'] += timeExtensionInMillis;

      if(washerQueueInstance != userQueueInstance) {
        washerQueueInstance['startTime'] += timeExtensionInMillis;
      }
      updatedQueueInstances.add(washerQueueInstance);
    }

    //If any data was collected on driers that need updates, update them
    if(infoAboutDriersToUpdate.isNotEmpty) {
      _updateDrierTimes(infoAboutDriersToUpdate, timeExtensionInMillis, queueDataList);
    }

    //Re-save all this data
    _reference.setData({
      'queue' : updatedQueueInstances
    });
  }

  ///Updates drier documents after a user has been granted an extension
  ///Only executed if a user queued at the washer queue where this user was granted an extension is also queued in a drier queue somewhere
  ///Takes in a map in the form key: machine number, value: lowest index, as well the duration to extend things by
  void _updateDrierTimes(Map<String, int> data, int timeExtensionInMillis, List<QueueData> queueListData) async {

    //Loop through all the information in the map and update times
    for(String machineNumber in data.keys) {

      //Holds the new updated list
      List<dynamic> updatedInstances = List<dynamic>();

      //Get the list of queueInstances
      List<QueueInstance> queueInstances = queueListData.singleWhere((queueData) => queueData.whichMachine
          == 'drier' && queueData.machineNumber == machineNumber).queueInstances;

      int startingIndex = data[machineNumber];

      //Add all the unaffected instances to the list
      List<QueueInstance> unAffectedList = queueInstances.getRange(0, startingIndex).toList();
      for(QueueInstance instance in unAffectedList) {
        updatedInstances.add(instance.toQueuingMap());
      }

      //Update all instances that need to be updated
      List<QueueInstance> listToUpdate = queueInstances.getRange(startingIndex, queueInstances.length).toList();
      for(QueueInstance queueInstance in listToUpdate) {
        Map<String, dynamic> instance = queueInstance.toQueuingMap();
        instance['startTime'] += timeExtensionInMillis;
        instance['endTime'] += timeExtensionInMillis;
        updatedInstances.add(instance);
      }

     await _fireStore.collection('drier queue').document(location)
          .collection(machineNumber).document('queued list').setData({
        'queue' : updatedInstances
      });
    }
  }

  //Skips a user if they have not confirmed to using the machine
  Future skipUser(QueueInstance userQueueInstance, List<QueueData> queueDataList) async {

    //Read the data and put the user at the end of the queue
    DocumentReference reference = _fireStore
        .collection(whichQueue)
        .document(location)
        .collection(machineNumber)
        .document('queued list');
    DocumentSnapshot snapshot = await reference.get();
    List<dynamic> queueInstances = snapshot.data['queue'];

    //Remove the user at the top of the queue and put them at the end
    queueInstances.removeAt(0);
    queueInstances.add(userQueueInstance.toQueuingMap());

    //Loop through the list and update start times
    int lastTimeAvailable = DateTime.now().millisecondsSinceEpoch;
    List<dynamic> updatedQueues = await _getUpdatedList(listToUpdate: queueInstances, lastTimeAvailable: lastTimeAvailable);

    //If the user is being skipped in the drier, ensure correct times
    if(whichQueue == 'drier queue') {
      updatedQueues = await _ensureCorrectTimes(updatedQueues, queueDataList);

      //Save the data
      await reference.setData({'queue': updatedQueues});

    } else {

      //First, save the new data with the user skipped (comes before the above)
      await reference.setData({'queue': updatedQueues});

      //Skip the user in the drier queue too since they are skipped in the washer queue
      await _reQueueDrier(QueueInstance.fromMap(updatedQueues.last), queueDataList);
    }

    return 'Done';
  }

  //Skips a user in the drier queue who has been skipped in the washer queue
  Future _reQueueDrier(QueueInstance userWasherQueueInstance, List<QueueData> queueDataList) async {

    //Holds the new list to save
    List<dynamic> updatedList = List<dynamic>();

    //Read the sta and see if the user is queued
    DocumentReference _reference = _fireStore.collection('drier queue').document(location).collection(machineNumber).document('queued list');
    DocumentSnapshot snapshot = await _reference.get();

    if(snapshot.data != null) {
    List<dynamic> queueInstances = snapshot.data['queue'];
    var userQueue = queueInstances.singleWhere((instance) => instance['user']['uid'] == userWasherQueueInstance.user.uid, orElse: () => null);

    //If the user is queued here, re-queue them in the drier
    if (userQueue != null) {
      //Get the index and save all the queues before this one
      int userIndex = queueInstances.indexOf(userQueue);

      //Add the ones before this as they do not need to be modified
      updatedList.addAll(queueInstances.getRange(0, userIndex));

      //For rest, start and end times need to be updated
      List<dynamic> instancesToUpdate = queueInstances.getRange(
          userIndex + 1, queueInstances.length).toList();
      instancesToUpdate.add(userQueue);
      int lastTimeAvailable;

      if (userIndex == 0 && queueInstances.length == 1) {
        lastTimeAvailable = userWasherQueueInstance.endTimeInMillis;
      } else if (userIndex == 0) {
        lastTimeAvailable = DateTime
            .now()
            .millisecondsSinceEpoch;
      } else {
        lastTimeAvailable = queueInstances[userIndex - 1]['endTime'];
      }

      for (var queue in instancesToUpdate) {
        //Get the start time and duration
        int duration = queue['endTime'] - queue['startTime'];
        int startTime = await getQueueTime(availableFrom: lastTimeAvailable);

        //Update the start and end times for this queue
        queue['startTime'] = startTime;
        queue['endTime'] = startTime + duration;

        //Update the last time available
        lastTimeAvailable = queue['endTime'];

        //if this one is the re-queued userQueue, double check that the start time is after washer end time
        if (queue == userQueue) {
          DateTime washerEndTime = DateTime.fromMillisecondsSinceEpoch(
              userWasherQueueInstance.endTimeInMillis);
          DateTime drierStartTime = DateTime.fromMillisecondsSinceEpoch(
              queue['startTime']);
          if (washerEndTime.isAfter(drierStartTime)
              || washerEndTime.isAtSameMomentAs(drierStartTime)
              || drierStartTime
                  .difference(washerEndTime)
                  .inMinutes < 5) {
            int startTime = await getQueueTime(
                availableFrom: userWasherQueueInstance.endTimeInMillis);
            queue['startTime'] = startTime;
            queue['endTime'] = startTime + duration;
          }
        }

        //Add the queue instance to the list
        updatedList.add(queue);
      }

      //Ensure that for other users, queue times match
      updatedList = await _ensureCorrectTimes(updatedList, queueDataList);

      //Save all this data again
      await _reference.setData({
        'queue': updatedList
      });
    }

    }

    return 'Done';
  }

  //Un-queues the user (before finishing the queue)
  Future unQueueUser({QueueInstance queue, List<QueueData> queueDataList}) async {

    //The updated list
    List<dynamic> updatedQueues = List<dynamic>();

    //Read the data and put the user at the end of the queue
    DocumentReference reference = _fireStore
        .collection(whichQueue)
        .document(location)
        .collection(machineNumber)
        .document('queued list');
    DocumentSnapshot snapshot = await reference.get();
    List<dynamic> queueInstances = snapshot.data['queue'];

    //Get the index of the user's queue instance
    int userIndex = queueInstances.indexWhere((instance) => instance['user']['uid'] == queue.user.uid);

    //The queue instances before this are not affected. Add them to the updated list
    updatedQueues.addAll(queueInstances.getRange(0, userIndex));

    //Get the queueInstances whose queue dates are to be updated
    List<dynamic> instancesToUpdate = queueInstances.getRange(userIndex + 1, queueInstances.length).toList();

    //Update start times in the list that needs to be updated and add this to updatedQueues
    int lastTimeAvailable = userIndex != 0 ? queueInstances[userIndex - 1]['endTime'] : DateTime.now().millisecondsSinceEpoch;
    List<dynamic> updatedInstances = await _getUpdatedList(lastTimeAvailable: lastTimeAvailable, listToUpdate: instancesToUpdate);
    updatedQueues.addAll(updatedInstances);

    List<String> uIDs = queue.usersQueuedWith;
    uIDs.add(queue.user.uid);

    if(whichQueue == 'washer queue') {
      for(String uid in uIDs) {
        bool queuedInDrier = _isAlsoQueuedInDrier(uid, queueDataList);
        if(!queuedInDrier) {
          await updateUserInfo({'currentlyQueued' : false}, passedUser: User(uid: uid));
        }
      }
    } else {
      for(String uid in uIDs) {
        await updateUserInfo({'currentlyQueued' : false}, passedUser: User(uid: uid));
      }

      //If this is the drier queue, check if the user's new queue time isn't before they are done washing
      updatedQueues = await _ensureCorrectTimes(updatedQueues, queueDataList);
    }

    //Save the new data
    reference.setData({
      'queue' : updatedQueues
    });

    return 'Done';
  }

  //Returns a list (to save in the drier) that ensures there is no conflict in queue times
  Future<List<dynamic>> _ensureCorrectTimes(List<dynamic> suggestedDrierQueueList, List<QueueData> queueDataList) async {

    //Holds the original queueDataList before it is modified
    List<QueueData> originalQueueDataList = List<QueueData>();
    originalQueueDataList.addAll(queueDataList);

    //Holds the currently updated drier list (to start, it's set to the suggestedDrierQueueList)
    List<dynamic> currentlyUpdatedList = suggestedDrierQueueList;

    //Remove all the drier information to get only the washers
    queueDataList.removeWhere((queueData) => queueData.whichMachine == 'drier');

    //Loop through all the washing machines and check if users queued there are also queued here
    for(int i = 0; i < queueDataList.length; i++) {
      QueueData queueData = queueDataList[i]; //Get the current
      for(int i = 0; i < queueData.queueInstances.length; i++) {
        QueueInstance queueInstance = queueData.queueInstances[i];

        //Check if this user is queued in this drier
        Map<String, dynamic> isQueuedData = _isQueuedInBothWasherAndDrier(queueInstance.toQueuingMap(),
            originalQueueDataList, specifiedDrierNumber: machineNumber);

        if(isQueuedData['queuedInBoth']) {

          //Holds the corrected drier queue list for this current washer instance
          List<dynamic> correctedForCurrentQueueInstance = List<dynamic>();

          //Get the drier instance for this queue
          Map<String, dynamic> userDrierInstance = currentlyUpdatedList.singleWhere((instance) =>
          instance['user']['uid'] == queueInstance.user.uid, orElse: () => null);

          //Make sure queue times match. If not update them
          DateTime washerEndTime = DateTime.fromMillisecondsSinceEpoch(queueInstance.endTimeInMillis);
          DateTime drierStartTime = DateTime.fromMillisecondsSinceEpoch(userDrierInstance['startTime']);

          //Update times if they do not 'match'
          if(drierStartTime.isBefore(washerEndTime)
              || drierStartTime.isAtSameMomentAs(washerEndTime)
              || drierStartTime.difference(washerEndTime).inMinutes < 5) {

            //Re update drier start times starting with at this user
            int userIndex = currentlyUpdatedList.indexOf(userDrierInstance);

            //Add the the ones before this user to the updated list as they don't need to be updated
            correctedForCurrentQueueInstance.addAll(suggestedDrierQueueList.getRange(0, userIndex));
            List<dynamic> listToUpdate = currentlyUpdatedList.getRange(userIndex, currentlyUpdatedList.length).toList();

            //Get the updated list and add to the correctedForCurrentQueueInstance list
            int lastTimeAvailable = washerEndTime.millisecondsSinceEpoch;
            List<dynamic> updatedList = await _getUpdatedList(lastTimeAvailable: lastTimeAvailable, listToUpdate: listToUpdate);
            correctedForCurrentQueueInstance.addAll(updatedList);

            //Update the list
            currentlyUpdatedList = correctedForCurrentQueueInstance;
          }
        }
      }
    }

    //Return the list
    return currentlyUpdatedList;
  }

  ///Gets whether the user uid (as represented by the uid) is also found in the drier
  bool _isAlsoQueuedInDrier(String uid, List<QueueData> queueDataList) {

    //Remove all the washer queueData(s)
    queueDataList.removeWhere((queueData) => queueData.whichMachine == 'washer');

    //Loop through all the drier machines to check if this uid is found there
    for(QueueData queueData in queueDataList) {
      for(int i = 0; i < queueData.queueInstances.length; i++) {
        QueueInstance queueInstance = queueData.queueInstances[i]; //Gets the current queue instance
        if(queueInstance.user.uid == uid || queueInstance.usersQueuedWith.contains(uid)) {
          return true;
        }
      }
    }

    return false;
  }

  ///Gets whether the user is queued in both the washing and drying machines
  ///Takes in the userWasherQueueInstance and loops through all the driers
  Map<String, dynamic> _isQueuedInBothWasherAndDrier(Map<String, dynamic> userWasherQueueInstance, List<QueueData> queueDataList, {String specifiedDrierNumber}) {
      String userUid = userWasherQueueInstance['user']['uid'];

      //Remove all the washer queueData(s)
      queueDataList.removeWhere((queueData) => queueData.whichMachine == 'washer');

      //If the drierMachineNumber is specified, we want to check for only this machine number. thus, remove all other machines 
      if(specifiedDrierNumber != null) {
        queueDataList.removeWhere((queueData) =>
        queueData.machineNumber != specifiedDrierNumber);
      }

      //The data about the drier instance
      int indexOfDrierInstance;
      String drierMachineNumber;

      //Loop through to see if the user is queued in drier
      Map<String, dynamic> userDrierInstance;

      //Loop through all the queue data instances to see if the user has a drier instance
      for(QueueData queueData in queueDataList) {
        for(int i = 0; i < queueData.queueInstances.length; i++) {
          QueueInstance queueInstance = queueData.queueInstances[i]; //Gets the current queue instance
          if(queueInstance.user.uid == userUid) {
            userDrierInstance = queueInstance.toQueuingMap();
            indexOfDrierInstance = i;
            drierMachineNumber = queueData.machineNumber;
          }
        }
      }

      if(userDrierInstance != null) {
        return {
          'queuedInBoth' : true,
          'drierInstance' : userDrierInstance,
          'drierMachineNumber' : drierMachineNumber,
          'indexInList' : indexOfDrierInstance,
        };
      }

    return {
        'queuedInBoth' : false,
      'drierInstance' : null,
      'drierMachineNumber' : null,
      'indexInList' : null,
    };
  }

  //Takes a list and updates the start times of all instances in the list, maintaining a five-minute gap
  Future<List<dynamic>> _getUpdatedList({int lastTimeAvailable, List<dynamic> listToUpdate}) async {

    //The new updated list
    List<dynamic> updatedList = List<dynamic>();

    for (var queue in listToUpdate) {
      int duration = queue['endTime'] - queue['startTime'];
      int startTime = await getQueueTime(availableFrom: lastTimeAvailable);

      queue['startTime'] = startTime;
      queue['endTime'] = startTime + duration;

      //Update the new available time and add the queue to the list
      lastTimeAvailable = queue['endTime'];
      updatedList.add(queue);
    }

    return updatedList;
  }

  //Makes sure users who are done are no longer in the queue
  Future cleanQueueList({String machineNumber, String whichQueue}) async {
    DocumentReference queueReference = _fireStore
        .collection(whichQueue)
        .document(location)
        .collection(machineNumber)
        .document('queued list');
    DocumentSnapshot snapshot = await queueReference.get();

    //If the data is null, return
    if (snapshot.data == null || snapshot.data['queue'].length == 0) {
      return 'Done';
    } else {
      //Otherwise, re-read all and remove queue instances with end times in the past
      List<dynamic> queueList = snapshot.data['queue'];
      int originalLength = queueList.length;

      queueList.removeWhere((queue) => DateTime.fromMillisecondsSinceEpoch(queue['endTime'])
              .isBefore(DateTime.now()));

      //Rewrite all the data if we need to refresh
      if (queueList.length != originalLength) {
        queueReference.setData({'queue': queueList});
      }

      return 'Done';
    }
  }

  //Cleans both the washer and drier at the location that the user is queued for
  Future refreshQueueLists({String washerMachineNumber, drierMachineNumber}) async {
    if (washerMachineNumber != null) {
      await cleanQueueList(
          machineNumber: washerMachineNumber, whichQueue: 'washer queue');
    }

    if (drierMachineNumber != null) {
      await cleanQueueList(
          machineNumber: drierMachineNumber, whichQueue: 'drier queue');
    }

    return 'Done';
  }


  //Recommends a machine depending on the shortest wait time
  Future<Map<String, dynamic>> recommendMachine({List<String> machines, String whichQueue}) async {
    String recommendedMachine = machines[0];
    int shortestWaitTime = await getQueueTime(
        machineNumber: recommendedMachine, whichQueue: whichQueue);

    for (String machine in machines) {
      int queueTime =
          await getQueueTime(machineNumber: machine, whichQueue: whichQueue);

      if (queueTime < shortestWaitTime) {
        shortestWaitTime = queueTime;
        recommendedMachine = machine;
      }
    }

    return {
      'machine': '$recommendedMachine (recommended)',
      'startTime': shortestWaitTime
    };
  }

  ///Gets the list of enabled machines from the database
  Future getMachines(String whichQueue, {bool onlyAddIfEnabled = true}) async {
    List<String> availableMachines = List<String>();
    Map<String, bool> machinesData = Map<String, bool>();
    DocumentSnapshot snapshot = await _fireStore.collection(whichQueue).document('Block ${user.block}').get();
    List machinesStates = snapshot.data['machines'];

    if(onlyAddIfEnabled) {
      for(int i = 0; i < machinesStates.length; i++) {
        if (machinesStates[i]) {
          availableMachines.add('${i + 1}');
        }
      }

      return availableMachines;
    }


    for(int i = 0; i < machinesStates.length; i++) {
      machinesData['${i + 1}'] = machinesStates[i];
    }

    return machinesData;
  }

  ///Loads the available washer and drier machines
  Future<Map<String, dynamic>> loadAvailableMachines({bool getEnabledOnly = true}) async{

    if(getEnabledOnly) {
      List<String> washingMachines = await getMachines('washer queue');
      List<String> dryingMachines = await getMachines('drier queue');

      return {
        'washers': washingMachines,
        'driers': dryingMachines
      };
    }

    Map<String, dynamic> washingMachines = await getMachines('washer queue', onlyAddIfEnabled: false);
    Map<String, dynamic> dryingMachines = await getMachines('drier queue', onlyAddIfEnabled: false);

    return {
      'washers': washingMachines,
      'driers': dryingMachines
    };

  }

  ///Gets the recommended drier and washer and their wait times
  ///Machines are recommended according to shortest wait time (the sooner one can queue, the better).
  ///Sometimes a user can 'patch' themselves in-between other users in the drier queue if they have the right duration and the right machine
  Future<Map<String, dynamic>> getRecommendedMachines() async {
    Map<String, dynamic> recommendWasher = await recommendMachine(
        machines: availableWashers, whichQueue: 'washer queue');
    Map<String, dynamic> recommendDrier = await recommendMachine(
        machines: availableDriers, whichQueue: 'drier queue');

    return {'washer': recommendWasher, 'drier': recommendDrier};
  }

//Gets the time that the user can start queuing for for this machine (in millis)
  ///If the last time available is known, we return five minutes from that time
  ///If there are no users queues, then we return five minutes from now
  ///If this is the drier queue and between users queued there is space to fit the user, return this time
  ///Else we return five minutes from the last user
  ///If the QueueDataList is passed, then the user is queuing for the DRIER after they queued for the washer
  Future<int> getQueueTime({String whichQueue, String machineNumber, int availableFrom, int washerEndTime, int drierDurationInMillis}) async {

    if (availableFrom != null) {
      return availableFrom + Duration(minutes: 5).inMilliseconds;
    }

    DocumentReference queuedListReference = _fireStore
        .collection(whichQueue ?? this.whichQueue)
        .document(location)
        .collection(machineNumber)
        .document('queued list');
    DocumentSnapshot snapshot = await queuedListReference.get();

    if (snapshot.data == null || snapshot.data['queue'].length == 0) {
      return DateTime.now().add(Duration(seconds: 5)).millisecondsSinceEpoch; //TODO revert back to minutes
    }

    List<dynamic> queueList = snapshot.data['queue'];

    //If washer end time is not null, the user needs to 'patched' between queue instances if they can fit (this only happens in the drier queue)
    if(washerEndTime != null &&  drierDurationInMillis != null) {

      //First, check if we can patch up at the very beginning
      int timeAbleToQueueFrom = (washerEndTime + Duration(minutes: 5).inMilliseconds);
      int endTimeWithLeeWay = timeAbleToQueueFrom + drierDurationInMillis + Duration(minutes: 5).inMilliseconds;
      int firstQueueStartTime = queueList[0]['startTime'];

      if(endTimeWithLeeWay <= firstQueueStartTime) {
        return timeAbleToQueueFrom;
      } else {

        //Check if we can patch somewhere in the middle, or afterwards
        for(int i = 0; i < queueList.length; i++) {
          int queueEndTime = queueList[i]['endTime'];
          int nextQueueStartTime = i == (queueList.length - 1) ? -1 : queueList[i + 1]['startTime']; //return - 1 so we know it's the last one
          int startTimeWithLeeWay = queueEndTime + Duration(minutes: 5).inMilliseconds;
          int endTimeWithLeeWay = startTimeWithLeeWay + drierDurationInMillis + Duration(minutes: 5).inMilliseconds;

          if(startTimeWithLeeWay >= timeAbleToQueueFrom && (endTimeWithLeeWay <= nextQueueStartTime || nextQueueStartTime == -1)) {
            return startTimeWithLeeWay;
          }
        }
      }
    }

    //Else, return five minutes from the last user (below code used mostly while queueing for the washing machine)
    QueueInstance lastUserQueued = QueueInstance.fromMap(queueList[queueList.length - 1]);

    //If five minutes after the time of the last queued user is in the past, return five minutes from now
    DateTime fiveMinutesFromQueueTimeOfLastUser = DateTime.fromMillisecondsSinceEpoch(lastUserQueued.endTimeInMillis).add(Duration(minutes: 5));
    DateTime now = DateTime.now();

    if (fiveMinutesFromQueueTimeOfLastUser.isBefore(now)) {
      return now.add(Duration(minutes: 5)).millisecondsSinceEpoch;
    } else {
      //Else, it's in the future. Make sure that there is the leeway of five minutes
      Duration durationDifference = fiveMinutesFromQueueTimeOfLastUser.difference(now);

      if (durationDifference.inMinutes >= 5) {
        return fiveMinutesFromQueueTimeOfLastUser.millisecondsSinceEpoch;
      }

      return now.add(Duration(minutes: 5)).millisecondsSinceEpoch;
    }

  }

  Map<String, Stream<DocumentSnapshot>> getQueueDataStreams() {
    Map<String, Stream<DocumentSnapshot>> streams =
        Map<String, Stream<DocumentSnapshot>>();

    //Add all the streams for the washer to the list
    for (String machine in availableWashers) {
      streams['washer:$machine'] = _fireStore
          .collection('washer queue')
          .document('Block ${user.block}')
          .collection(machine)
          .document('queued list')
          .snapshots();
    }

    //Add all the streams for the drier to the list
    for (String machine in availableDriers) {
      streams['drier:$machine'] = _fireStore
          .collection('drier queue')
          .document('Block ${user.block}')
          .collection(machine)
          .document('queued list')
          .snapshots();
    }

    return streams;
  }
}

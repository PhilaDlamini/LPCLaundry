
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundryqueue/models/Queue.dart';
import 'package:laundryqueue/models/User.dart';

class DatabaseService {
  static final Firestore _fireStore = Firestore.instance;
  final CollectionReference _users = _fireStore.collection('users');
  final String uid;
  final User user;
  final List<String> availableWashers;
  final List<String> availableDriers;

  DatabaseService({this.uid, this.user, this.availableDriers, this.availableWashers});

  Stream<QuerySnapshot> get usersStream => _users.snapshots();

  //Updates user information in the database
  Future<dynamic> updateUserInfo(Map<String, String> data) async {
    return await _users.document(uid).setData(data);
  }

  // Gets the user data for this uid
  Future<User> getUser() async {
    DocumentSnapshot snapshot = await _users.document(uid).get();
    return User.fromMap(snapshot.data);
  }

  //Queues the user for the specified machine at the specified location
  Future<dynamic> queue(Queue queue, {String whichQueue}) async {
    DocumentReference queuedListReference = _fireStore.collection(whichQueue).document(queue.location).collection(queue.which).document('queued list');
    DocumentSnapshot snapshot = await queuedListReference.get();

    //If the data is null, this is the first time a user is queuing up. Just save the queue instance
    if(snapshot.data == null) {
      queuedListReference.setData({
        'queue' : [
         queue.toQueuingMap(),
        ]
      });
    } else {

      //Otherwise, re-read all the data and save it
      List<dynamic> queueList = snapshot.data['queue'];
      queueList.add(queue.toQueuingMap());
      queuedListReference.setData({
        'queue' : queueList
      });
    }
 }

 //Un-queues the user when they are done using the machine
  Future finishQueue({Queue queue, String whichQueue, String location, String machineNumber}) async {

    //Get the data from the queue
    DocumentReference reference = _fireStore.collection(whichQueue)
        .document(location).collection(machineNumber).document('queued list');
    DocumentSnapshot snapshot = await reference.get();

    //Remove the user from the list
    List<dynamic> usersQueued = snapshot.data['queue'];
    usersQueued.removeWhere((item) => item['user']['uid'].trim() == queue.user.uid);

    //Re-save the data
    reference.setData({
      'queue' : usersQueued,
    });

    return 'Done';
  }

 //Recommends a machine depending on the shortest wait time
 Future<Map<String , dynamic>> recommendMachine({List<String> machines, String whichQueue, String location}) async {
   String recommendedMachine = machines[0];
   int shortestWaitTime = await getQueueTime(whichQueue: whichQueue,
       location: location,
       machineNumber: recommendedMachine);

   for (String machine in machines) {
     int queueTime = await getQueueTime(
         whichQueue: whichQueue, location: location, machineNumber: machine);

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

//Gets recommended washer and drier and their wait times
Future<Map<String, dynamic>> getRecommendedMachines({String location}) async {

     Map<String, dynamic> recommendWasher = await recommendMachine(machines: availableWashers, whichQueue: 'washer queue', location: location);
     Map<String, dynamic> recommendDrier = await recommendMachine(machines: availableDriers, whichQueue: 'drier queue', location: location);

     return {
       'washer' : recommendWasher,
       'drier' : recommendDrier
     };

}


//Gets the time that the user can start queuing for for this machine (in millis)
Future<int> getQueueTime({String whichQueue, String machineNumber, String location}) async {

  DocumentReference queuedListReference = _fireStore.collection(whichQueue).document(location)
      .collection(machineNumber).document('queued list');
  DocumentSnapshot snapshot = await queuedListReference.get();

  //If the data is null, return the time five minutes from now
  if(snapshot.data == null || snapshot.data['queue'].length == 0 ) {
    DateTime fiveMinutesFromNow = DateTime.now().add(Duration(minutes: 5));
    return fiveMinutesFromNow.millisecondsSinceEpoch;
  }

  //Else, read the list and get five minutes from the latest queue instance
  List<dynamic> queueList = snapshot.data['queue'];
  Queue lastUserQueued = Queue.fromMap(queueList[queueList.length - 1]);

  //If five minutes after the time of the last queued user is in the past, return five minutes from now
  DateTime fiveMinutesFromQueueTimeOfLastUser = DateTime.fromMillisecondsSinceEpoch(lastUserQueued.endTimeInMillis).add(Duration(minutes: 5));

  DateTime now = DateTime.now();

  if(fiveMinutesFromQueueTimeOfLastUser.isBefore(now)) {
    return now.add(Duration(minutes: 5)).millisecondsSinceEpoch;
  }

  //Make sure that there is the leeway of five minutes exists
  Duration durationDifference = fiveMinutesFromQueueTimeOfLastUser.difference(now);
  print('Duration difference: $durationDifference');

  if(durationDifference.inMinutes >= 5) {
    return fiveMinutesFromQueueTimeOfLastUser.millisecondsSinceEpoch;
  }

  return now.add(Duration(minutes: 5)).millisecondsSinceEpoch;

}

Map<String, Stream<DocumentSnapshot>> getQueueDataStreams() {

    Map<String, Stream<DocumentSnapshot>> streams = Map<String, Stream<DocumentSnapshot>>();

    //Add all the streams for the washer to the list
    for(String machine in availableWashers) {
      streams['washer:$machine'] =
      _fireStore.collection('washer queue').document('Block ${user.block}').collection(machine).document('queued list').snapshots();
    }

    //Add all the streams for the drier to the list
    for(String machine in availableDriers) {
      streams['drier:$machine'] =
          _fireStore.collection('drier queue').document('Block ${user.block}').collection(machine).document('queued list').snapshots();
    }

    return streams;
}


}
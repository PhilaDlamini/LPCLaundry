import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/storage.dart';
import 'package:laundryqueue/widgets/loading.dart';

class QueuePage extends StatefulWidget {
  final bool isWashing;
  final bool isDrying;
  final List<User> usersQueuingWith;
  final Map<String, dynamic> availableMachines;
  final QueueInstance washerQueueInstance;

  QueuePage(
      {this.isWashing,
      this.washerQueueInstance,
      this.usersQueuingWith,
      this.isDrying,
      this.availableMachines});

  @override
  State<StatefulWidget> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<String> durations = [
    'Select duration',
    '15 minutes',
    '25 minutes',
    '35 minutes',
    '45 minutes',
    '60 minutes'
  ];
  List<String> washerMachines;
  List<String> drierMachines;
  String currentWasherDuration = 'Select duration';
  String currentDrierDuration = 'Select duration';
  String washerQueuedFor;
  String drierQueuedFor;
  User user;
  bool queuingJointly;
  bool queuingForDrierAfterWasher;
  List<User> usersQueuingWith;

  //Gets the start time
  DateTime washerQueueTime;
  DateTime washerEndTime;
  DateTime drierQueueTime;
  DateTime drierEndTime;

  bool firstTimeBuilding = true;
  bool alreadyQueued = false; //In case the user clicks the button twice
  bool isWashing;
  bool isDrying;
  TextStyle machineName = TextStyle(fontSize: 18, fontWeight: FontWeight.w800);

  void _updateList(List<String> machines, String updateWith) {
    for (String machine in machines) {
      if (machine == updateWith.split(' ')[0]) {
        int index = machines.indexOf(machine);
        machines[index] = updateWith;
      }
    }
  }

  //Resets the machines
  void _resetMachineList(List<String> machines){
    for(String machine in machines) {
      int index = machines.indexOf(machine);
      machines[index] = machine.split(' ')[0];
    }
  }

  DateTime _correctDrierStartTime() {
    //Get the washer start time from the washer queue instance
    DateTime washerEndTime = DateTime.fromMillisecondsSinceEpoch(
        widget.washerQueueInstance.endTimeInMillis);

    //At this moment, the drier queue time might be before the washer end time
    if (drierQueueTime.isBefore(washerEndTime) ||
        drierQueueTime.isAtSameMomentAs(washerEndTime) ||
        drierQueueTime.difference(washerEndTime).inMinutes < 5) {
      drierQueueTime = washerEndTime.add(Duration(minutes: 5));
    }

    return drierQueueTime;
  }

  Future _updateStartTimes() async {
    washerQueueTime = DateTime.fromMillisecondsSinceEpoch(await DatabaseService(
      location: 'Block ${user.block}',
      whichQueue: 'washer queue',
    ).getQueueTime(
      machineNumber: washerQueuedFor,
    ));

    washerEndTime = washerQueueTime.add(Duration(
        minutes: currentWasherDuration == 'Select duration'
            ? 0
            : int.parse(currentWasherDuration.split(' ')[0])));

    int drierDurationInMillis = Duration(
            minutes: (currentDrierDuration == 'Select duration'
                ? 0
                : int.parse(currentDrierDuration.split(' ')[0])))
        .inMilliseconds;

    drierQueueTime = DateTime.fromMillisecondsSinceEpoch(await DatabaseService(
      location: 'Block ${user.block}',
      whichQueue: 'drier queue',
    ).getQueueTime(
      machineNumber: drierQueuedFor,
      washerEndTime: isWashing
          ? washerEndTime.millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch,
      drierDurationInMillis: drierDurationInMillis,
    ));

    if (isWashing && isDrying) {
      if (washerEndTime.isAfter(drierQueueTime) ||
          washerEndTime.isAtSameMomentAs(drierQueueTime)) {
        drierQueueTime = washerEndTime.add(Duration(minutes: 5));
      } else {
        Duration difference = drierQueueTime.difference(washerEndTime);
        if (difference.inMinutes < 5) {
          drierQueueTime = washerEndTime.add(Duration(minutes: 5));
        }
      }

      drierEndTime = drierQueueTime.add(Duration(
          minutes: currentDrierDuration == 'Select duration'
              ? 0
              : int.parse(currentDrierDuration.split(' ')[0])));
    } else if (isWashing) {
      //The use is only washing
      drierQueueTime = null;
    } else if (queuingForDrierAfterWasher) {
      washerQueueTime = null;
      washerEndTime = null;

      drierQueueTime = _correctDrierStartTime();
      drierEndTime = drierQueueTime.add(Duration(
          minutes: currentDrierDuration == 'Select duration'
              ? 0
              : int.parse(currentDrierDuration.split(' ')[0])));
    } else {
      //The user is only drying
      washerQueueTime = null;
      washerEndTime = null;

      drierEndTime = drierQueueTime.add(Duration(
          minutes: currentDrierDuration == 'Select duration'
              ? 0
              : int.parse(currentDrierDuration.split(' ')[0])));
    }
  }

  Future _getRecommendMachines() async {
    if (firstTimeBuilding) {

      //Firs, make sure the machines are reset (none have '(recommended)' behind in case this is the second time)
      _resetMachineList(washerMachines);
      _resetMachineList(drierMachines);

      Map<String, dynamic> recommendMachines = await DatabaseService(
              location: 'Block ${user.block}',
              availableWashers: washerMachines,
              availableDriers: drierMachines)
          .getRecommendedMachines();

      washerQueuedFor = recommendMachines['washer']['machine'];
      drierQueuedFor = recommendMachines['drier']['machine'];

      //Update the lists to show which machine is recommended
      _updateList(washerMachines, washerQueuedFor);
      _updateList(drierMachines, drierQueuedFor);

      //The start times for the machines
      washerQueueTime = DateTime.fromMillisecondsSinceEpoch(
          recommendMachines['washer']['startTime']);
      washerEndTime = washerQueueTime;
      drierQueueTime = DateTime.fromMillisecondsSinceEpoch(
          recommendMachines['drier']['startTime']);

      if (queuingForDrierAfterWasher) {
        drierQueueTime = _correctDrierStartTime();
      }

      drierEndTime = drierQueueTime;

      firstTimeBuilding = false;
    }

    return 'Done';
  }

  void _queueUser() async {
    if (!alreadyQueued) {
      if (_formKey.currentState.validate()) {
        await _updateStartTimes();

        List<String> usersQueuedWith = usersQueuingWith != null
            ? usersQueuingWith.map((user) => user.uid).toList()
            : null;

        //Create the drier and washer instance queue instances
        QueueInstance washer = isWashing
            ? QueueInstance(
                which: washerQueuedFor.split(' ')[0],
                location: 'Block ${user.block}',
                timeQueuedInMillis: DateTime.now().millisecondsSinceEpoch,
                user: user,
                startTimeInMillis: washerQueueTime.millisecondsSinceEpoch,
                endTimeInMillis: washerEndTime.millisecondsSinceEpoch,
                usersQueuedWith: usersQueuedWith,
              )
            : null;

        QueueInstance drier = isDrying
            ? QueueInstance(
                which: drierQueuedFor.split(' ')[0],
                location: 'Block ${user.block}',
                user: user,
                timeQueuedInMillis: DateTime.now().millisecondsSinceEpoch,
                startTimeInMillis: drierQueueTime.millisecondsSinceEpoch,
                usersQueuedWith: usersQueuedWith,
                endTimeInMillis: drierEndTime.millisecondsSinceEpoch)
            : null;

        if (isWashing && isDrying) {
          await DatabaseService(whichQueue: 'washer queue').queue(washer);
          await DatabaseService(whichQueue: 'drier queue').queue(drier);
        } else if (isWashing) {
          await DatabaseService(whichQueue: 'washer queue').queue(washer);
        } else {
          await DatabaseService(whichQueue: 'drier queue').queue(drier);
        }

        //Mark these users as having been queued
        usersQueuedWith.add(user.uid);
        for (String uid in usersQueuedWith) {
          await DatabaseService().updateUserInfo({'currentlyQueued': true},
              passedUser: User(uid: uid));
        }

        alreadyQueued = true;

        //Return to default route (where we go to the home page)
        Navigator.popUntil(
            context, ModalRoute.withName(Navigator.defaultRouteName));
      }
    }
  }

  Widget _getDrierCard() {
    return Container(
      height: 250,
      padding: EdgeInsets.only(top: isWashing ? 16 : 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.all(0),
                trailing: GestureDetector(
                  child: Icon(Icons.clear),
                  onTap: () async {
                    //If we are also not washing, then both card aren't displayed. Go back
                    if (!isWashing) {
                      Navigator.pop(context);
                    } else {
                      isDrying = false;
                      await _updateStartTimes();
                      setState(() {});
                    }
                  },
                ),
                title: Row(
                  children: <Widget>[
                    Text(
                      'Drier',
                      style: machineName,
                    ),
                    Center(child: dot),
                    Text('#${drierQueuedFor.split(' ')[0]}',
                        style: TextStyle(fontSize: 13))
                  ],
                ),
                subtitle: Text(
                  '${drierQueueTime.hour}:${drierQueueTime.minute} - ${drierEndTime.hour}:${drierEndTime.minute}',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Container(height: 2, width: 50, color: Colors.yellow),
              ),
              DropdownButtonFormField(
                  decoration: dropDownButtonDecoration,
                  items: drierMachines.map((item) {
                    return DropdownMenuItem(
                        value: item, child: Text('Drier #$item'));
                  }).toList(),
                  value: drierQueuedFor,
                  onChanged: (val) async {
                    drierQueuedFor = val;
                    await _updateStartTimes();
                    setState(() {});
                  }),
              DropdownButtonFormField(
                  decoration: dropDownButtonDecoration,
                  validator: (val) =>
                      (isDrying && currentDrierDuration == 'Select duration')
                          ? 'Select duration'
                          : null,
                  items: durations.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  value: currentDrierDuration,
                  onChanged: (val) async {
                    currentDrierDuration = val;
                    await _updateStartTimes();
                    setState(() {});
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getWasherCard() {
    return Container(
      height: 235,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.all(0),
                trailing: GestureDetector(
                  child: Icon(Icons.clear),
                  onTap: () async {
                    //If we are also not drying, then both cards aren't displayed. Go back
                    if (!isDrying) {
                      Navigator.pop(context);
                    } else {
                      isWashing = false;

                      await _updateStartTimes();
                      setState(() {});
                    }
                  },
                ),
                title: Row(
                  children: <Widget>[
                    Text(
                      'Washer',
                      style: machineName,
                    ),
                    Center(child: dot),
                    Text('#${washerQueuedFor.split(' ')[0]}',
                        style: TextStyle(fontSize: 13))
                  ],
                ),
                subtitle: Text(
                  '${washerQueueTime.hour}:${washerQueueTime.minute} - ${washerEndTime.hour}:${washerEndTime.minute}',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Container(height: 2, width: 50, color: Colors.yellow),
              ),
              DropdownButtonFormField(
                  decoration: dropDownButtonDecoration,
                  items: washerMachines.map((item) {
                    return DropdownMenuItem(
                        value: item, child: Text('Washer #$item'));
                  }).toList(),
                  value: washerQueuedFor,
                  onChanged: (val) async {
                    washerQueuedFor = val;
                    await _updateStartTimes();
                    setState(() {});
                  }),
              DropdownButtonFormField(
                  decoration: dropDownButtonDecoration,
                  validator: (val) =>
                      (isWashing && currentWasherDuration == 'Select duration')
                          ? 'Select duration'
                          : null,
                  items: durations.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text('$item'),
                    );
                  }).toList(),
                  value: currentWasherDuration,
                  onChanged: (val) async {
                    currentWasherDuration = val;
                    await _updateStartTimes();
                    setState(() {});
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getBottomSheet() {
    return Container(
      height: 200,
      color: Color(0xFF737373),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Queueing with',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Spacer(),
                GestureDetector(
                    child: Icon(Icons.clear),
                    onTap: () {
                      Navigator.pop(context);
                    })
              ],
            ),
            Expanded(
              flex: 1,
              child: ListView.builder(
                  itemCount: usersQueuingWith.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.all(0),
                      leading: FutureBuilder(
                        future: StorageService(user: usersQueuingWith[index])
                            .getImageURL(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: NetworkImage(snapshot.data),
                                ),
                              ),
                            );
                          }

                          return CircleAvatar(
                            backgroundColor: Colors.yellow,
                          );
                        },
                      ),
                      title: Text(usersQueuingWith[index].name,
                          style: TextStyle(fontSize: 16)),
                      subtitle: Text(
                          'Block ${usersQueuingWith[index].block}/${usersQueuingWith[index].room}'),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet() {
    Timer.run(() {
      if (queuingJointly) {
        showModalBottomSheet(
            context: context, builder: (context) => _getBottomSheet());
      }
    });
  }

  @override
  void initState() {
    isWashing = widget.isWashing;
    isDrying = widget.isDrying;
    usersQueuingWith = widget.usersQueuingWith;
    queuingJointly = usersQueuingWith.isNotEmpty;
    queuingForDrierAfterWasher =
        isDrying && !isWashing && widget.washerQueueInstance != null;
    drierMachines = widget.availableMachines['driers'];
    washerMachines = widget.availableMachines['washers'];
    _showBottomSheet();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    user = ModalRoute.of(context).settings.arguments;

    return FutureBuilder(
      future: _getRecommendMachines(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Loading();
        }

        return Scaffold(
          backgroundColor: Colors.yellow,
          appBar: AppBar(
            elevation: 0,
            title: Text('Queue in block ${user.block}',
                style: TextStyle(color: Colors.black)),
            leading: GestureDetector(
              child: Icon(Icons.clear, color: Colors.black),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 32.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Theme(
                      data: ThemeData(
                        canvasColor: Colors.blueGrey[100],
                      ),
                      child: Column(
                        children: <Widget>[
                          isWashing ? _getWasherCard() : Container(),
                          isDrying ? _getDrierCard() : Container(),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: queuingJointly
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 180,
                            child: Row(
                              children: <Widget>[
                                roundedButton(
                                    onTapped: _queueUser,
                                    color: Colors.white,
                                    text: 'Queue'),
                                roundedButton(
                                  text: 'Others',
                                  onTapped: () {
                                    _showBottomSheet();
                                  },
                                )
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: 100,
                          child: roundedButton(
                              onTapped: _queueUser,
                              color: Colors.white,
                              text: 'Queue'),
                        ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

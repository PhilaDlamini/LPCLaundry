import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class QueuePage extends StatefulWidget {
  final bool isWashing;
  final bool isDrying;

  QueuePage({this.isWashing = true, this.isDrying = true});

  @override
  State<StatefulWidget> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final FlutterLocalNotificationsPlugin _notificationPlugin =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<String> washerMachines = ['1', '2', '3'];
  final List<String> drierMachines = ['1', '2'];
  final List<String> durations = [
    'Select duration',
    '2 minutes',
    '15 minutes',
    '30 minutes',
    '45 minutes',
    '60 minutes'
  ]; //Check from downstairs
  String currentWasherDuration = 'Select duration';
  String currentDrierDuration = 'Select duration';
  String washerQueuedFor;
  String drierQueuedFor;
  User user;

  //Gets the start time
  DateTime washerQueueTime;
  DateTime washerEndTime;
  DateTime drierQueueTime;
  DateTime drierEndTime;

  bool firstTimeBuilding = true;
  bool isWashing;
  bool isDrying;

  @override
  void initState() {
    isWashing = widget.isWashing;
    isDrying = widget.isDrying;
    super.initState();
  }

  void _updateList(List<String> list, String updateWith) {
    for (String item in list) {
      if (item == updateWith.split(' ')[0]) {
        int index = list.indexOf(item);
        list[index] = updateWith;
      }
    }
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

    int drierDurationInMillis = Duration(minutes: (currentDrierDuration == 'Select duration' ? 0 : int.parse(currentDrierDuration.split(' ')[0])))
    .inMilliseconds;

    drierQueueTime = DateTime.fromMillisecondsSinceEpoch(await DatabaseService(
      location: 'Block ${user.block}',
      whichQueue: 'drier queue',
    ).getQueueTime(
      machineNumber: drierQueuedFor,
      washerEndTime: isWashing ? washerEndTime.millisecondsSinceEpoch : DateTime.now().millisecondsSinceEpoch,
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
      //Get the machines
      Map<String, dynamic> recommendMachines = await DatabaseService(location: 'Block ${user.block}',
              availableWashers: washerMachines, availableDriers: drierMachines)
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
      drierEndTime = drierQueueTime;

      firstTimeBuilding = false;
    }

    return 'Done';
  }

  void _queueUser() async {
    if (_formKey.currentState.validate()) {
      //Make sure queue times are up to date
      await _updateStartTimes();

      //Create the drier and washer instance queue instances
      QueueInstance washer = isWashing
          ? QueueInstance(
              which: washerQueuedFor.split(' ')[0],
              location: 'Block ${user.block}',
              timeQueuedInMillis: DateTime.now().millisecondsSinceEpoch,
              user: user,
              startTimeInMillis: washerQueueTime.millisecondsSinceEpoch,
              endTimeInMillis: washerEndTime.millisecondsSinceEpoch,
            )
          : null;

      QueueInstance drier = isDrying
          ? QueueInstance(
              which: drierQueuedFor.split(' ')[0],
              location: 'Block ${user.block}',
              user: user,
              timeQueuedInMillis: DateTime.now().millisecondsSinceEpoch,
              startTimeInMillis: drierQueueTime.millisecondsSinceEpoch,
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

      Navigator.pop(context); //We do need this??
    }
  }

  Widget _getDrierCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            ListTile(
              leading: CircleAvatar(
                radius: 25.0,
                backgroundColor: Colors.brown[300],
              ),
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
              title: Text('Drier'),
              subtitle: Text(
                  '#${drierQueuedFor.split(' ')[0]}, ${drierQueueTime.hour}:${drierQueueTime.minute} - ${drierEndTime.hour}:${drierEndTime.minute}'),
            ),
            DropdownButtonFormField(
                decoration: inputTextDecoration, //Change this later
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
                decoration: inputTextDecoration,
                //Change this later
                validator: (val) => (isDrying &&
                        currentDrierDuration == 'Select duration')
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
    );
  }

  Widget _getWasherCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            ListTile(
              leading: CircleAvatar(
                radius: 25.0,
                backgroundColor: Colors.blue[300],
              ),
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
              title: Text('Washing machine'),
              subtitle: Text(
                  '#${washerQueuedFor.split(' ')[0]}, ${washerQueueTime.hour}:${washerQueueTime.minute} - ${washerEndTime.hour}:${washerEndTime.minute}'),
            ),
            DropdownButtonFormField(
                decoration: inputTextDecoration, //Change this later
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
                decoration: inputTextDecoration,
                //Change this later
                validator: (val) => (isWashing &&
                        currentWasherDuration == 'Select duration')
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
    );
  }

  @override
  Widget build(BuildContext context) {
    user = ModalRoute.of(context).settings.arguments;

    return FutureBuilder(
        future: _getRecommendMachines(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(child: Text('Loading...'));
          }

          return Scaffold(
            body: Container(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Queing in Block ${user.block}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    isWashing ? _getWasherCard() : Container(),
                    Center(
                      child: Row(
                        children: <Widget>[dot, Text('Then'), dot],
                      ),
                    ),
                    isDrying ? _getDrierCard() : Container(),
                    RaisedButton(onPressed: _queueUser, child: Text("Queue"))
                  ],
                ),
              ),
            ),
          );
        });
  }
}

import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:laundryqueue/models/Queue.dart';
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
    '1 minutes',
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
    _notificationPlugin.initialize(
        InitializationSettings(
            AndroidInitializationSettings('@mipmap/ic_launcher'),
            IOSInitializationSettings()),
        onSelectNotification: (String data) async {
      await Navigator.pushNamed(context, '/home');
    });
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
    washerQueueTime = DateTime.fromMillisecondsSinceEpoch(
        await DatabaseService().getQueueTime(
      location: 'Block ${user.block}',
      whichQueue: 'washer queue',
      machineNumber: washerQueuedFor,
    ));

    washerEndTime = washerQueueTime.add(Duration(
        minutes: currentWasherDuration == 'Select duration'
            ? 0
            : int.parse(currentWasherDuration.split(' ')[0])));

    drierQueueTime = DateTime.fromMillisecondsSinceEpoch(
        await DatabaseService().getQueueTime(
      location: 'Block ${user.block}',
      whichQueue: 'drier queue',
      machineNumber: drierQueuedFor,
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
      Map<String, dynamic> recommendMachines = await DatabaseService(
              availableWashers: washerMachines, availableDriers: drierMachines)
          .getRecommendedMachines(location: 'Block ${user.block}');

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

  //Schedules a notification to display five minutes before the user's queue starts
  void _scheduleNotifications(String machine, Queue queue) async {

    //Only schedule notifications if the user opted to receive
    bool notifyOnTurn = await Preferences.getBoolData(
        Preferences.NOTIFY_ON_TURN);
    bool notifyWhenDone = await Preferences.getBoolData(
        Preferences.NOTIFY_WHEN_DONE);

    print('$notifyOnTurn, $notifyWhenDone');

    if (notifyOnTurn) {
      DateTime fiveMinutesBeforeQueueStart = DateTime.fromMillisecondsSinceEpoch(queue.startTimeInMillis)
          .subtract(Duration(minutes: 5));

      //If it's passed already, show the notification now. Otherwise, schedule it
      if (fiveMinutesBeforeQueueStart.isBefore(DateTime.now()) || fiveMinutesBeforeQueueStart.isAtSameMomentAs(DateTime.now())) {
        _notificationPlugin.show(0, 'Your turn is close', 'Your turn to use the $machine starts at ${queue.displayableTime['startTime']}',
            NotificationDetails(
                AndroidNotificationDetails('chanel id', 'chanel name', 'channel description'),
                IOSNotificationDetails()),
            payload: 'Some data here');
      } else {
        _notificationPlugin.schedule(0, 'Your turn is close', 'Your turn to use the $machine starts at ${queue.displayableTime['startTime']}',
            fiveMinutesBeforeQueueStart,
            NotificationDetails(AndroidNotificationDetails(CHANNEL_ID, CHANNEL_NAME, CHANNEL_DESCRIPTION),
                IOSNotificationDetails()),
            payload: 'Some data here');
      }
    }

    if (notifyWhenDone) {
      //Also, schedule a notification for when the queue ends
      String title = '${machine == 'drier'
          ? 'Drying finished'
          : 'Washing finished'}';
      String body = '${machine == 'drier'
          ? 'Your clothes were done drying at ${queue
          .displayableTime['endTime']}'
          : 'Your clothes were done washing at ${queue
          .displayableTime['endTime']}'}';

      DateTime queueEnd =
      DateTime.fromMillisecondsSinceEpoch(queue.endTimeInMillis);
      _notificationPlugin.schedule(0, title, body, queueEnd,
          NotificationDetails(
              AndroidNotificationDetails(CHANNEL_ID, CHANNEL_NAME, CHANNEL_DESCRIPTION),
              IOSNotificationDetails()));
    }
  }

  void _queueUser() async {
    if (_formKey.currentState.validate()) {
      //Make sure queue times are up to date
      await _updateStartTimes();

      //Create the drier and washer instance queue instances
      Queue washer = isWashing
          ? Queue(
              which: washerQueuedFor.split(' ')[0],
              location: 'Block ${user.block}',
              timeQueuedInMillis: DateTime.now().millisecondsSinceEpoch,
              user: user,
              startTimeInMillis: washerQueueTime.millisecondsSinceEpoch,
              endTimeInMillis: washerEndTime.millisecondsSinceEpoch,
            )
          : null;

      Queue drier = isDrying
          ? Queue(
              which: drierQueuedFor.split(' ')[0],
              location: 'Block ${user.block}',
              user: user,
              timeQueuedInMillis: DateTime.now().millisecondsSinceEpoch,
              startTimeInMillis: drierQueueTime.millisecondsSinceEpoch,
              endTimeInMillis: drierEndTime.millisecondsSinceEpoch)
          : null;

      if (isWashing && isDrying) {
        //Schedules the notifications and save data
        _scheduleNotifications('drier', drier);
        _scheduleNotifications('washer', washer);

        await DatabaseService().queue(washer, whichQueue: 'washer queue');
        await DatabaseService().queue(drier, whichQueue: 'drier queue');
      } else if (isWashing) {
        _scheduleNotifications('washer', washer);
        await DatabaseService().queue(washer, whichQueue: 'washer queue');
      } else {
        _scheduleNotifications('drier', drier);
        await DatabaseService().queue(drier, whichQueue: 'drier queue');
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
                        currentDrierDuration == 'Select valid duration')
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
                        currentWasherDuration == 'Select valid duration')
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

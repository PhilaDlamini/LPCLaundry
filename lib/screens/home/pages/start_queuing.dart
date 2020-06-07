import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/home/pages/choose.dart';
import 'package:laundryqueue/screens/home/pages/queue_page.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class StartQueuing extends StatelessWidget {
  final User user;

  StartQueuing({this.user});

  Future<List> getQueueData() async {
    String washerData =
        await Preferences.getStringData(Preferences.LAST_WASHER_USED_DATA);
    String drierData =
        await Preferences.getStringData(Preferences.LAST_DRIER_USED_DATA);

    //Decode the data into maps and create Queue instances
    QueueInstance washerQueue = washerData != null
        ? QueueInstance.fromMap(json.decode(washerData))
        : null;
    QueueInstance drierQueue = drierData != null
        ? QueueInstance.fromMap(json.decode(drierData))
        : null;

    //Return the list
    return [washerQueue, drierQueue];
  }

  Widget summary(QueueInstance queue, String whichMachine) {
    return Container(
        margin: EdgeInsets.only(top: 16.0),
        child: queue != null
            ? Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      dot,
                      Text('$whichMachine #${queue.which}')
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      dot,
                      Text(
                          'Finished ${whichMachine == 'Drier' ? 'drying' : 'washing'} ${getDate(queue)}')
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      dot,
                      Text('Queued @ ${queue.displayableTime['timeQueued']}')
                    ],
                  ),
                ],
              )
            : Container(
                child: Text('No recent data for ${whichMachine.toLowerCase()}'),
              ));
  }

  String getDate(QueueInstance queue) {
    DateTime endTime =
        DateTime.fromMillisecondsSinceEpoch(queue.endTimeInMillis);
    DateTime now = DateTime.now();
    int dayDifference = now.day - endTime.day;

    String date;
    String time = '${endTime.hour}:${endTime.minute}';

    if (dayDifference == 0) {
      date = 'today';
    } else if (dayDifference == 1) {
      date = 'yesterday';
    } else {
      date = '${endTime.day}/${endTime.month}';
    }
    return '$date, $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          child: Icon(Icons.menu, color: Colors.black),
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: <Widget>[popupMenuButton],
      ),
      body: Container(
        padding: EdgeInsets.only(top: 100),
        child: Column(children: <Widget>[
          Text(
            'Summary',
            style: TextStyle(fontSize: 18),
          ),
          FutureBuilder(
            future: getQueueData(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: <Widget>[
                    summary(snapshot.data[0], 'Washing machine'),
                    summary(snapshot.data[1], 'Drier'),
                  ],
                );
              }
              return Container();
            },
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: RaisedButton(
                child: Text('Queue'),
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChooseUsers(user: user),
                    ),
                  );
                }),
          ),
        ]),
      ),
    );
  }
}

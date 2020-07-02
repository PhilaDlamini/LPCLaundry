import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/drawer_pages/profile.dart';
import 'package:laundryqueue/screens/home/pages/choose.dart';
import 'package:laundryqueue/screens/home/pages/queue_page.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/services/storage.dart';
import 'package:laundryqueue/widgets/queue_summary.dart';

class StartQueuing extends StatefulWidget {
  final User user;
  final Map<String, dynamic> availableMachines;

  StartQueuing({this.user, this.availableMachines});

  @override
  State<StatefulWidget> createState() => _StartQueuingState();

}

class _StartQueuingState extends State<StartQueuing> {

  void _toggle() {
    setState(() {});
  }

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


  Widget _summaryWidget(
      QueueInstance washerInstance, QueueInstance drierInstance, double height) {
    if (washerInstance != null && drierInstance != null) {
      return Column(
        children: <Widget>[
          QueueSummary(queueInstance: washerInstance, title: 'Washer', toggle: _toggle,),
          QueueSummary(queueInstance: drierInstance, title: 'Drier', toggle: _toggle,)
        ],
      );
    } else if (washerInstance != null) {
      return QueueSummary(queueInstance: washerInstance, title: 'Washer', toggle: _toggle,);
    } else if (drierInstance != null) {
      return QueueSummary(queueInstance: drierInstance, title: 'Drier', toggle: _toggle,);
    }

    return Container(
      height: height,
      child: Center(
        child: Container(
          height: 250,
          child: Column(
            children: <Widget>[
              Container(
                width: 80,
                child: Row(children: <Widget>[
                  Icon(
                    Icons.star_border,
                    color: Colors.black,
                  ),
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.black,
                    size: 30,
                  ),
                  Icon(
                    Icons.star_border,
                    color: Colors.black,
                  ),
                ]),
              ),
              Text('Click the button\nbelow to start queuing',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 16))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    double height = mediaQueryData.size.height;

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        elevation: 0,
        title: Text('Laundry'),
        leading: GestureDetector(
          child: Icon(Icons.menu, color: Colors.black),
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: <Widget>[
          GestureDetector(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FutureBuilder(
                future: StorageService(user: widget.user).getImageURL(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return Container(
                      width: 24,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircleAvatar(
                          backgroundImage: NetworkImage(snapshot.data)
                      ),
                  ),
                    )
                    ],
                  );

                  },
              ),
            ),
          )
        ],
      ),
      body: Container(
        height: height,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: FutureBuilder(
            future: getQueueData(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _summaryWidget(snapshot.data[0], snapshot.data[1], height);
              }
              return Container();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // backgroundColor: Colors.greenAccent,
        label: Text('Queue'),
        icon: Icon(Icons.queue),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChooseUsers(
                user: widget.user,
                availableMachines: widget.availableMachines,
              ),
            ),
          );
        },
      ),
    );
  }
}

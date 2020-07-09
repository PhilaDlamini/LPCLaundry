import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class Settings extends StatefulWidget {
  final User user;

  Settings({this.user});

  @override
  State<StatefulWidget> createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  bool notifyOnTurn;
  bool notifyWhenDone;
  bool notifyOnQueuedJointly;

  Widget checkbox(String description, bool value) {
    return ListTile(
        contentPadding: EdgeInsets.all(0),
        leading: Checkbox(
            value: value,
            onChanged: (val) async {
              switch (description) {
                case Preferences.NOTIFY_ON_TURN_DESCRIPTION:
                  notifyOnTurn = val;
                  await Preferences.updateBoolData(
                      Preferences.NOTIFY_ON_TURN, notifyOnTurn);
                  break;

                case Preferences.NOTIFY_WHEN_DONE_DESCRIPTION:
                  notifyWhenDone = val;
                  await Preferences.updateBoolData(
                      Preferences.NOTIFY_WHEN_DONE, notifyWhenDone);
                  break;

                case Preferences.NOTIFY_WHEN_QUEUED_JOINTLY:
                  notifyOnQueuedJointly = val;
                  await Preferences.updateBoolData(
                      Preferences.NOTIFY_WHEN_QUEUED_JOINTLY,
                      notifyOnQueuedJointly);
                  break;
              }
              setState(() {});
            }),
        title: Text(
          description,
          maxLines: 3,
        ));
  }

  Future _initialize() async {
    notifyWhenDone =
        await Preferences.getBoolData(Preferences.NOTIFY_WHEN_DONE);
    notifyOnTurn = await Preferences.getBoolData(Preferences.NOTIFY_ON_TURN);
    notifyOnQueuedJointly =
        await Preferences.getBoolData(Preferences.NOTIFY_WHEN_QUEUED_JOINTLY);
    return 'Done';
  }

  @override
  Widget build(BuildContext context) {


    return FutureBuilder(
        future: _initialize(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: Text("Settings", style: TextStyle(color: Colors.black)),
                actions: <Widget>[
                  popupMenuButton(context, user: widget.user)
                ],
                elevation: 0,
                leading: GestureDetector(
                  child: Icon(Icons.clear, color: Colors.black),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              body: Container(
                padding: EdgeInsets.only(right: 16, left: 16, bottom: 16, top: 0),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    checkbox(
                        Preferences.NOTIFY_ON_TURN_DESCRIPTION, notifyOnTurn),
                    checkbox(Preferences.NOTIFY_WHEN_DONE_DESCRIPTION,
                        notifyWhenDone),
                    checkbox(Preferences.NOTIFY_WHEN_QUEUED_JOINTLY,
                        notifyOnQueuedJointly),
                  ],
                ),
              ),
            );
          }

          return Container();
        });
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  AuthService _auth = AuthService();
  bool notifyOnTurn;
  bool notifyWhenDone;

  Widget checkbox(String description, bool value) {
    return ListTile(
      contentPadding: EdgeInsets.all(0),
      leading: Checkbox(
          value: value,
          onChanged: (val) async {

            switch (description) {
              case Preferences.NOTIFY_ON_TURN_DESCRIPTION:
                notifyOnTurn = val;
                await Preferences.updateBoolData(Preferences.NOTIFY_ON_TURN, notifyOnTurn);
                break;

              case Preferences.NOTIFY_WHEN_DONE_DESCRIPTION:
                notifyWhenDone = val;
                await Preferences.updateBoolData(Preferences.NOTIFY_WHEN_DONE, notifyWhenDone);
                break;
            }
            setState(() {});
          }),
      title: Text(description, maxLines: 2,)
    );
  }

  Future _initialize() async {
    notifyWhenDone = await Preferences.getBoolData(Preferences.NOTIFY_WHEN_DONE);
    notifyOnTurn = await Preferences.getBoolData(Preferences.NOTIFY_ON_TURN);
    return 'Done';
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
        future: _initialize(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {

            print('$notifyOnTurn, $notifyWhenDone');

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: Text("Settings", style: TextStyle(color: Colors.black)),
                actions: <Widget>[
                  GestureDetector(
                    child: Icon(Icons.more_vert, color: Colors.black),
                  )
                ],
                elevation: 0,
                leading: GestureDetector(
                  child: Icon(Icons.clear, color:Colors.black),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              body: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Notifications',
                          style: TextStyle(fontSize: 18, ),
                        ),
                      ),
                    ),
                    checkbox(
                        Preferences.NOTIFY_ON_TURN_DESCRIPTION, notifyOnTurn),
                    checkbox(Preferences.NOTIFY_WHEN_DONE_DESCRIPTION,
                        notifyWhenDone)
                  ],
                ),
              ),
            );
          }

          return Container();
        });
  }
}

import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/screens/authenticate/authenticate.dart';
import 'package:laundryqueue/screens/drawer_pages/info.dart';
import 'package:laundryqueue/screens/home/home.dart';
import 'package:laundryqueue/screens/home/pages/verify_email.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/widgets/disconnected.dart';
import 'package:laundryqueue/widgets/loading.dart';
import 'package:provider/provider.dart';
import 'models/User.dart';

class Wrapper extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WrapperState();
}

class WrapperState extends State<Wrapper> {
  User user;
  bool isFirstTimeLoggedIn;
  Map<String, dynamic> availableMachines;
  FirebaseUser refreshedFirebaseUser;

  void _toggle() {
    setState(() {});
  }

  Future _initialize(FirebaseUser firebaseUser) async {
    user = await DatabaseService(uid: firebaseUser.uid).getUser();
    isFirstTimeLoggedIn =
        await Preferences.getBoolData(Preferences.FIRST_TIME_LOGGED_IN);
    availableMachines =
        await DatabaseService(user: user).loadAvailableMachines();
    refreshedFirebaseUser = await AuthService().getUser();
    return 'Done';
  }

  @override
  Widget build(BuildContext context) {
    FirebaseUser firebaseUser = Provider.of<FirebaseUser>(context);
    ConnectivityResult connectivityResult = Provider.of<ConnectivityResult>(context);
    if (connectivityResult != ConnectivityResult.none) {
      if (firebaseUser == null) {
        return Authenticate(
          toggleWrapper: _toggle,
        );
      }
      else {
        return FutureBuilder(
          future: _initialize(firebaseUser),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              bool isEmailVerified = refreshedFirebaseUser.isEmailVerified;

              if (isEmailVerified) {
                if (isFirstTimeLoggedIn) {
                  Timer.run(
                        () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Info(
                                  user: user,
                                  isFirstTime: true,
                                ),
                          ),
                        ),
                  );
                }

                return DataInheritedWidget(
                  user: user,
                  machines: availableMachines,
                  child: Home(),
                );
              } else {
                return VerifyEmail(
                    firebaseUser: firebaseUser,
                    user: user,
                    toggle: _toggle
                );
              }
            }

            return Loading(
              longDuration: true,
            );
          },
        );
      }
    } else {
      return Disconnected();
    }
  }
}

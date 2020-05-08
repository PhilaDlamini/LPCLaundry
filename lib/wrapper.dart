import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:laundryqueue/inherited_widgets/user_inherited_widget.dart';
import 'package:laundryqueue/screens/authenticate/authenticate.dart';
import 'package:laundryqueue/screens/home/home.dart';
import 'package:laundryqueue/screens/home/pages/queue_page.dart';
import 'package:laundryqueue/streams/count_down.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/widgets/loading.dart';
import 'package:provider/provider.dart';
import 'models/User.dart';

class Wrapper extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WrapperState();
}

class WrapperState extends State<Wrapper> {

  @override
  Widget build(BuildContext context) {
    final FirebaseUser firebaseUser = Provider.of<FirebaseUser>(context);

    if (firebaseUser != null) {
      return FutureBuilder(
        future: DatabaseService(uid: firebaseUser.uid).getUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Loading();
          }

          //We have access to the user instance from firebase (snapshot.data)
          return UserInheritedWidget(
            user: snapshot.data,
            child: Home(),
          );
        },
      );
    } else {
      return Authenticate();
    }
  }
}
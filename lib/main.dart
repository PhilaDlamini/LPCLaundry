import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/screens/drawer_pages/profile.dart';
import 'package:laundryqueue/screens/home/home.dart';
import 'package:laundryqueue/screens/home/pages/choose.dart';
import 'package:laundryqueue/screens/home/pages/queue_page.dart';
import 'package:laundryqueue/screens/drawer_pages/settings.dart';
import 'package:laundryqueue/screens/home/pages/queued.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/wrapper.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(StreamProvider<FirebaseUser>.value(
    value: AuthService().userStream,
   catchError: (context, err) {
      print(err.toString());
      //Return null (why should this return a user?)
      return null;
   },
    child: MaterialApp(
      title: 'LPC laundry',
      home: Wrapper(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColorDark: Colors.purple[700]),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => Home(),
        '/profile': (BuildContext context) => Profile(),
        '/queuePage': (BuildContext context) => QueuePage(),
        '/settings': (BuildContext context) => Settings(),
        '/queueList' : (BuildContext context) => Queued(),
        '/wrapper' : (BuildContext context) => Wrapper(),
        '/choose' : (BuildContext context) => ChooseUsers()
      },
    ),
  ));
}

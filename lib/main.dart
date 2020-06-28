import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundryqueue/screens/drawer_pages/machines.dart';
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
      theme: ThemeData(
        primaryColor: Colors.yellow[500],
        primaryColorDark: Colors.yellow[900],
        accentColor: Colors.pinkAccent,
        scaffoldBackgroundColor: Colors.white,
//        textTheme: GoogleFonts.robotoTextTheme( //This is the default though
//        ),
      ),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => Home(),
        '/machines': (BuildContext context) => Machines(),
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

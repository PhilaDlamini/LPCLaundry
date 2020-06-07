  import 'dart:convert';

import 'package:flutter/material.dart';
  import 'package:fluttertoast/fluttertoast.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
  import 'package:laundryqueue/services/shared_preferences.dart';

  ///All constant variables
  const String CHANNEL_NAME = 'Channel name';
  const String CHANNEL_ID = 'Channel id';
  const String CHANNEL_DESCRIPTION = 'Channel description';
  const int WASHER_NOTIFY_ON_TURN_ID = 1234;
  const int DRIER_NOTIFY_ON_TURN_ID = 5678;
  const int WASHER_NOTIFY_WHEN_DONE_ID = 9101;
  const int DRIER_NOTIFY_WHEN_DONE_ID = 1213;
  const int START_TIME_ALARM_ID = 98242;
  const int SKIP_TIME_ALARM_ID = 10232;
  const int FINISH_QUEUE_ID = 49503;
  const int QUEUED_JOINTLY_IN_WASHER = 23222;
  const int QUEUED_JOINTLY_IN_DRIER = 33333;

  ///All constant decorations
  const InputDecoration createAccountInputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.white,
        width: 2.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.pink,
        width: 2.0,
      ),
    ),
  );

  const InputDecoration editProfileInputDecoration = InputDecoration();

  BoxDecoration dropDownDecoration = BoxDecoration(
      border: Border.all(
          width: 1.0, style: BorderStyle.solid, color: Colors.blueGrey),
      borderRadius: BorderRadius.all(Radius.circular(5)));

  const BoxDecoration circleBox = BoxDecoration(shape: BoxShape.circle);

  ///All constant widgets
  Container dot = Container(
    width: 10,
    height: 10,
    margin: EdgeInsets.only(right: 16.0),
    decoration: circleBox.copyWith(color: Colors.grey),
  );

  PopupMenuButton popupMenuButton = PopupMenuButton<int>(
    icon: Icon(
      Icons.more_vert,
      color: Colors.black,
    ),
    onSelected: (value) {
      //Do something
    },
    itemBuilder: (context) => <PopupMenuEntry<int>>[
      const PopupMenuItem(
        value: 1,
        child: Text('Account'),
      ),
      const PopupMenuItem(
        value: 1,
        child: Text('Settings'),
      ),
      const PopupMenuItem(
        value: 1,
        child: Text('Info'),
      ),
    ],
  );


  Widget marker(String text) {
    return Container(
      margin: EdgeInsets.only(left: 4),
      width: 30,
      height: 15,
      child: Center(
          child: Text(
        text,
        style: TextStyle(fontSize: 10, color: Colors.black),
      )),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
    );
  }

  ///All constant methods
  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        backgroundColor: Colors.blueGrey[400],
        textColor: Colors.black,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM);
  }

  Future resetMachineConfirmation(String key) async {
    await Preferences.updateBoolData(key, false);
  }




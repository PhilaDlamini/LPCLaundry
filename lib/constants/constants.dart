import 'package:flutter/material.dart';

//Strings
const String CHANNEL_NAME = 'Channel name';
const String CHANNEL_ID = 'Channel id';
const String CHANNEL_DESCRIPTION = 'Channel description';
const int WASHER_NOTIFY_ON_TURN_ID = 1234;
const int DRIER_NOTIFY_ON_TURN_ID = 5678;
const int WASHER_NOTIFY_WHEN_DONE_ID= 9101;
const int DRIER_NOTIFY_WHEN_DONE_ID= 1213;
const int START_TIME_ALARM_ID = 98242;
const int SKIP_TIME_ALARM_ID = 10232;
const int FINISH_QUEUE_ID = 49503;

const InputDecoration inputTextDecoration = InputDecoration(
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

BoxDecoration dropDownDecoration = BoxDecoration(
    border: Border.all(width: 1.0, style: BorderStyle.solid, color: Colors.blueGrey),
    borderRadius: BorderRadius.all(Radius.circular(5))
);

const BoxDecoration circleBox = BoxDecoration(
  shape: BoxShape.circle
);

Container dot = Container(
  width: 10,
  height: 10,
  margin: EdgeInsets.only(right: 16.0),
  decoration: circleBox.copyWith(color: Colors.grey),
);
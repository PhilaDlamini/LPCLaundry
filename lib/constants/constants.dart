import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/drawer_pages/info.dart';
import 'package:laundryqueue/screens/drawer_pages/machines.dart';
import 'package:laundryqueue/screens/drawer_pages/feedback_screen.dart';
import 'package:laundryqueue/screens/drawer_pages/profile.dart';
import 'package:laundryqueue/screens/drawer_pages/settings.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/widgets/custom_dialog.dart';

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
const int PROFILE = 1;
const int MACHINES = 2;
const int SETTINGS = 3;
const int INFO = 4;
const int FEEDBACK = 5;

///All constant decorations
const InputDecoration textFormDecoration = InputDecoration(
    contentPadding: EdgeInsets.all(10),
    fillColor: Colors.white,
    filled: true,
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: Colors.grey,
          width: 1.0,
        )
    ),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: Colors.redAccent,
          width: 1.0,
        )
    ),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8),),
        borderSide: BorderSide(
          color: Colors.yellow,
          width: 1.0,
        )
    )
);

const InputDecoration dropDownButtonDecoration = InputDecoration.collapsed();

BoxDecoration dropDownDecoration = BoxDecoration(
    border: Border.all(
        width: 1.0, style: BorderStyle.solid, color: Colors.blueGrey),
    borderRadius: BorderRadius.all(Radius.circular(5)));

const BoxDecoration circleBox = BoxDecoration(shape: BoxShape.circle);

///All constant widgets
Widget textFormField(String title,
    {Function onChanged, Function validator, String initialValue, InputDecoration decoration = textFormDecoration, bool obscureText = false}) {
  return Container(
    width: 250,
    margin: EdgeInsets.only(top: 16),
    child: Column(children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey[900]),
          ),
        ),
      ),
      TextFormField(
        style: TextStyle(fontSize: 14),
        cursorColor: Colors.yellow,
        obscureText: obscureText,
        onChanged: onChanged,
        validator: validator,
        decoration: decoration,
        initialValue: initialValue,
      ),
    ]),
  );
}

Widget feedbackTextInput({Function onChanged, Function validator, String hintText, double height,}) {
  return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                hintText,
                style: TextStyle(fontSize: 15, color: Colors.blueGrey[900]),
              ),
            ),
          ),
          Container(
            height: height,
            child: TextFormField(
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                cursorColor: Colors.yellow,
                onChanged: onChanged,
                validator: validator,
                expands: true,
                minLines: null,
                maxLines: null,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type something',
                )
            ),
          ),
        ],
      );
}

Widget profileDataTile({Icon icon, String title, String value}) {
  return ListTile(
    contentPadding: EdgeInsets.all(0),
    leading: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        icon
      ],
    ),
    title: Text(
      title,
      style: TextStyle(fontSize: 13, color: Colors.grey[900]),
    ),
    subtitle: Text(value,
        style: TextStyle(fontSize: 16, color: Colors.grey[900])
    ),
  );
}

Widget profileEditTile(
    {Icon icon, String title, String initialValue, Function onChanged, Function validator}) {
  return Row(
    children: <Widget>[
      Container(
          padding: EdgeInsets.only(right: 32),
          child: icon),
      textFormField(title,
        onChanged: onChanged,
        validator: validator,
        initialValue: initialValue,
      )
    ],
  );
}

Widget roundedButton(
    {Function onTapped, String text, Color color = Colors.yellow}) {
  return InkWell(
    onTap: onTapped,
    splashColor: Colors.yellow,
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Center(child: Text(text,
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),)),
    ),
  );
}

Widget flatButton({String text, Function onPressed}) {
  return FlatButton(
    splashColor: Colors.yellowAccent[100],
    child: Text(text),
    onPressed: onPressed,
  );
}

Widget circleButton({Color color, Function onPressed, Icon icon}) {
  return Container(
    height: 50,
    width: 50,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    ),
    child: IconButton(
        icon: icon,
        onPressed: onPressed
    ),
  );
}

Widget circularButton({Function onTap, Icon icon}) {
  return InkWell(
    splashColor: Colors.yellow,
    onTap: onTap,
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              width: 1,
              color: Colors.blueGrey
          )
      ),
      child: icon,
    ),
  );
}

Widget authTitle(String text) {
  return Container(
    padding: EdgeInsets.only(bottom: 24),
    child: Text(text, style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),),
  );
}

Container dot = Container(
  width: 2,
  height: 2,
  margin: EdgeInsets.only(left: 8, right: 8.0),
  decoration: circleBox.copyWith(color: Colors.blueGrey),
);

Container bigDot = Container(
  width: 10,
  height: 10,
  margin: EdgeInsets.only(right: 8.0, left: 40),
  decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.blueGrey,
        width: 1,
      )
  ),
);

Widget popupMenuButton(BuildContext context, {User user}) {
  return PopupMenuButton<int>(
    icon: Icon(
      Icons.more_vert,
      color: Colors.black,
    ),
    onSelected: (value) {
      switch (value) {
        case PROFILE:
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => Profile(user: user,)
          ),
          );

          break;

        case MACHINES:
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => Machines(user: user,)
          ),
          );
          break;

        case SETTINGS:
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => Settings(user: user)
          ),
          );
          break;

        case INFO:
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => Info(user: user)
          ),
          );
          break;

        case FEEDBACK:
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => FeedbackScreen(user: user)
          ),
          );
          break;
      }
    },

    itemBuilder: (context) =>
    <PopupMenuEntry<int>>[
      const PopupMenuItem(
        value: PROFILE,
        child: Text('Profile'),
      ),
      const PopupMenuItem(
        value: MACHINES,
        child: Text('Machines'),
      ),
      const PopupMenuItem(
        value: SETTINGS,
        child: Text('Settings'),
      ),
      const PopupMenuItem(
        value: FEEDBACK,
        child: Text('Feedback'),
      ),
      const PopupMenuItem(
        value: INFO,
        child: Text('Info'),
      )
    ],
  );
}

Widget marker(String text) {
  return Container(
    margin: EdgeInsets.only(right: 4),
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

Widget infoQueueButton() {
  return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: Colors.pinkAccent,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.queue, color: Colors.white, size: 15,),
          SizedBox(width: 4,),
          Text('Queue', style: TextStyle(color: Colors.white, fontSize: 12),)
        ],
      )
  );
}

Widget infoExtendButton() {
  return Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            width: 1,
            color: Colors.blueGrey
        )
    ),
    child: Icon(Icons.extension, size: 15, color: Colors.blueGrey,),
  );
}

///All constant methods
void showToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.blueGrey[200],
      textColor: Colors.black,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM);
}

Future resetMachineConfirmation(String key) async {
  await Preferences.updateBoolData(key, false);
}

void showDisableMachineDialog(BuildContext context, {Function onPositiveTap}) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          CustomDialog(
            title: 'Warning',
            message: 'If you disable this machine, others in your block will not be able to queue here.'
                ' A machine should only be disabled if it is not working, and/or has been removed from your block.'
                ' Are you sure you want to disable this machine?',
            positiveOnTap: onPositiveTap,
            negativeButtonName: 'No',
            positiveButtonName: 'Yes',
          )
  );
}

void showEnableMachineDialog(BuildContext context, {Function onPositiveTap}) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          CustomDialog(
            title: 'Enable machine',
            message: 'Enable this machine so others in your block can queue here. By enabling it, you vow that it is working properly.'
                ' Are you sure you want to enable this machine?',
            positiveOnTap: onPositiveTap,
            negativeButtonName: 'No',
            positiveButtonName: 'Yes',
          )
  );
}

void showUnQueueConfirmationDialog(BuildContext context,
    {Function onConfirmed}) async {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        CustomDialog(
          title: 'Leave queue',
          message: 'If you quit, you will be removed from the queue before you are done using the machine, and others '
              'will go in your place. To use this machine, you will have to queue again. Are you sure you want to quit?',
          negativeButtonName: 'Cancel',
          positiveButtonName: 'Yes',
          positiveOnTap: onConfirmed,
        ),
  );
}

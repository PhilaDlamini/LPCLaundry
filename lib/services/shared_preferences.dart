import 'package:shared_preferences/shared_preferences.dart';

class Preferences {

  static const String NOTIFY_ON_TURN = 'Notify on turn';
  static const String NOTIFY_WHEN_DONE = 'Notify when done';

  //The descriptions for the checkboxes. Used in Settings.dart
  static const String NOTIFY_ON_TURN_DESCRIPTION = "Receive a notification when your turn in the queue is near";
  static const String NOTIFY_WHEN_DONE_DESCRIPTION = "Receive a notification your your clothes are done washing/drying";

  static Future initializeInstance() async {

  }

  static Future initializePreferences() async {
    await updateBoolData(NOTIFY_ON_TURN, true);
    await updateBoolData(NOTIFY_WHEN_DONE, true);
  }

  static Future updateBoolData(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  static Future<bool> getBoolData(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }
}
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {

  static const String NOTIFY_ON_TURN = 'Notify on turn';
  static const String NOTIFY_WHEN_DONE = 'Notify when done';
  static const String WASHER_USE_CONFIRMED = 'Washer use confirmed';
  static const String DRIER_USE_CONFIRMED = 'Drier use confirmed';
  static const String LAST_WASHER_USED_DATA = 'Last washer used data';
  static const String LAST_DRIER_USED_DATA = 'Last drier used data';
  static const String RECENT_USER_DRIER_QUEUE_INSTANCE = 'Recent user drier queue instance';
  static const String RECENT_USER_WASHER_QUEUE_INSTANCE = 'Recent user washer queue instance';

  //The descriptions for the checkboxes. Used in Settings.dart
  static const String NOTIFY_ON_TURN_DESCRIPTION = "Receive a notification when your turn in the queue is near";
  static const String NOTIFY_WHEN_DONE_DESCRIPTION = "Receive a notification your your clothes are done washing/drying";

  static Future initializePreferences() async {
    await updateBoolData(NOTIFY_ON_TURN, true);
    await updateBoolData(NOTIFY_WHEN_DONE, true);
    await updateBoolData(WASHER_USE_CONFIRMED, false);
    await updateBoolData(DRIER_USE_CONFIRMED, false);
    await updateStringData(LAST_WASHER_USED_DATA, null);
    await updateStringData(LAST_DRIER_USED_DATA, null);
    await updateStringData(RECENT_USER_DRIER_QUEUE_INSTANCE, null);
    await updateStringData(RECENT_USER_WASHER_QUEUE_INSTANCE, null);
  }

  static Future updateBoolData(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  static Future<bool> getBoolData(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future updateStringData(String key, String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, data);
  }

  static Future getStringData(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

}
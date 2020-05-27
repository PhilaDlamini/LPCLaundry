import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Returns a stream of users (or null when they signed out)
  Stream<FirebaseUser> get userStream => _auth.onAuthStateChanged;

  //Sign in anonymously
  Future<dynamic> signInAnon() async {
    try {
      AuthResult result = await _auth.signInAnonymously();

      if (result.user != null) {
        User user = User(uid: result.user.uid);
        await DatabaseService(uid: user.uid).updateUserInfo(user.toMap());
        return user;
      }
      return null;
    } catch (e) {
      return e;
    }
  }

  //Sign in with email and password
  Future<dynamic> sigInWithEmailAndPassword(
      {String email, String password}) async {
    try {
      AuthResult result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user != null ? User(uid: result.user.uid) : null;
    } catch (e) {
      return e;
    }
  }

  //Register with email and password
  Future<dynamic> registerWithEmailAndPassword(
      {String name,
      String email,
      String password,
      String block,
      String room}) async {
    try {
      AuthResult result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (result.user != null) {
        User user = User(uid: result.user.uid, name: name, room: room, block: block);
        await DatabaseService(uid: user.uid).updateUserInfo(user.toMap());
        return user;
      }
      return null;
    } catch (e) {
      return e;
    }
  }

  // Signs the user user out
  Future<dynamic> signOut() async {
    //Reset preferences for the next user
    await Preferences.initializePreferences();
    try {
      return await _auth.signOut();
    } catch (e) {
      return e;
    }
  }
}

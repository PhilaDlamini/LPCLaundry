import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/services/storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Returns a stream of users (or null when they signed out)
  Stream<FirebaseUser> get userStream => _auth.onAuthStateChanged;

  //Sign in anonymously
  Future<dynamic> signInAnon() async {
    try {
      AuthResult result = await _auth.signInAnonymously();

      if (result.user != null) {
        User user = User(uid: result.user.uid, currentlyQueued: false);
        await DatabaseService(user: user).setUserInfo();
        return user;
      }
      return null;
    } catch (e) {
      return e;
    }
  }

  //Sign in with email and password
  Future<dynamic> sigInWithEmailAndPassword({String email, String password}) async {
    try {
      AuthResult result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user != null ? User(uid: result.user.uid, currentlyQueued: false) : null;
    } catch (e) {
      return e;
    }
  }

  //Register with email and password
  Future<dynamic> registerWithEmailAndPassword({String name, String email, String password, String block, String room, File file}) async {

    try {
      AuthResult result = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        User user = User(uid: result.user.uid, name: name, room: room, block: block, email: email, currentlyQueued: false);
        await StorageService(file: file, user: user).uploadImage();
        await DatabaseService(user: user).setUserInfo();
        return user;
      }
      return null;
    } catch (e) {
      return e;
    }
  }

  // Signs the user user out
  Future<dynamic> signOut() async {
    await Preferences.setDefaultPreferences();
    try {
      return await _auth.signOut();
    } catch (e) {
      return e;
    }
  }

  //Deletes the user account
  Future deleteAccount(User user) async {
     await StorageService(user: user).removeUserImage();
     await DatabaseService(user: user).removeUserInfo();
     FirebaseUser firebaseUser = await _auth.currentUser();
     await firebaseUser.delete();
  }
}

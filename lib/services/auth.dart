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

  Future sendVerificationEmail(FirebaseUser firebaseUser) async {
    bool isEmailSent =
        await Preferences.getBoolData(Preferences.VERIFICATION_EMAIL_SENT);
    try {
      if (!isEmailSent) {
        await firebaseUser.sendEmailVerification();
        await Preferences.updateBoolData(
            Preferences.VERIFICATION_EMAIL_SENT, true);
      }
      return 'Done';
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
      await Preferences.setDefaultPreferences();
      return result.user != null
          ? User(uid: result.user.uid, currentlyQueued: false)
          : null;
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
      String room,
      File file}) async {
    try {
      AuthResult result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (result.user != null) {
        User user = User(
            uid: result.user.uid,
            name: name,
            room: room,
            block: block,
            email: email,
            currentlyQueued: false);
        await StorageService(file: file, user: user).uploadImage();
        await DatabaseService(user: user).setUserInfo();
        await Preferences.setDefaultPreferences();
        return user;
      }
      return null;
    } catch (e) {
      return e;
    }
  }

  // Signs the user user out
  Future<dynamic> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      return e;
    }
  }

  //Enables the user to reset their password
  Future sendPasswordResetEmail(String email) async {
    bool isEmailSent = await Preferences.getBoolData(Preferences.PASSWORD_RESET_EMAIL_SENT);
    try{
      if(!isEmailSent) {
        await _auth.sendPasswordResetEmail(email: email);
        await Preferences.updateBoolData(Preferences.PASSWORD_RESET_EMAIL_SENT, true);
      } else {
        return 'The password reset email has already been sent to $email';
        //This means that if the email was sent but then the user types in a different email, we will display this message :)
      }
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

  //Refreshes the current user and returns (where we then check if they are verified)
  Future<FirebaseUser> getUser() async {
    FirebaseUser user = await _auth.currentUser();
    await user.reload();
    return await _auth.currentUser();
  }
}

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:laundryqueue/models/User.dart';

class StorageService {
  final User user;
  final File file;
  FirebaseStorage _storage = FirebaseStorage.instance;

  StorageService({this.user, this.file});

  Future uploadImage() async {

    try {
      StorageReference storageReference = _storage.ref().child('profile pictures').child(user.uid);
      StorageUploadTask storageUploadTask = storageReference.putFile(file);
      StorageTaskSnapshot snapshot = await storageUploadTask.onComplete;

      if(storageUploadTask.isComplete && storageUploadTask.isSuccessful) {
        var downloadURL = await snapshot.ref.getDownloadURL();
        return downloadURL.toString();
      }
    } catch (e) {
      return e;
    }

  }

  Future getImageURL() async {
    try {
      StorageReference storageReference = _storage.ref().child('profile pictures').child(user.uid);
      return (await storageReference.getDownloadURL()).toString();
    } catch (e) {
      return null;
    }
  }

  Future removeUserImage() async => await _storage.ref().child('profile pictures').child(user.uid).delete();

}
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/storage.dart';
import 'package:laundryqueue/widgets/loading.dart';

class Profile extends StatefulWidget {
  final User user;

  Profile({this.user});

  @override
  State<StatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  User user;
  bool isEditing;
  bool isLoading;
  File _file;
  String name;
  String block;
  String room;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future _pickImage() async {
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() => _file = file);
  }

  @override
  void initState() {
    user = widget.user;
    name = user.name;
    block = user.block;
    room = user.room;
    isEditing = false;
    isLoading = false;
    super.initState();
  }

  Widget getProfilePicture() {
    //Holds the profile picture
    FutureBuilder profilePicture = FutureBuilder(
        future: StorageService(user: user).getImageURL(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      fit: BoxFit.fill, image: NetworkImage(snapshot.data))),
            );
          }

          return Container();
        });

    return Container(
      width: 140,
      child: Stack(
        children: <Widget>[
          isEditing
              ? _file != null
              ? Container(
            width: 130,
            height: 130,
            child: Image.file(_file),
          )
              : profilePicture
              : profilePicture,
          isEditing
              ? Container(
            // Is it only restricted to the height + width of the container
            width: 130,
            height: 130,
            child: Align(
              alignment: Alignment.bottomRight,
              child: InkResponse(
                onTap: _pickImage,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )
              : Container(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Loading()
        : Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        leading: GestureDetector(
          child: Icon(
            Icons.clear,
            color: Colors.black,
          ),
          onTap: () {
            Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
          },
        ),
        title: Text('Profile', style: TextStyle(color: Colors.black)),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: isEditing
                ? Container()
                : GestureDetector(
                child: Icon(Icons.edit, color: Colors.black),
                onTap: () {
                  setState(() => isEditing = true);
                }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                getProfilePicture(),
                SizedBox(height: 16),
                profileDataTile(
                  icon: Icon(
                    Icons.email,
                    color: Colors.blueGrey,
                  ),
                  title: 'Email',
                  value: user.email,
                ),
                isEditing
                    ? profileEditTile(
                  title: 'Name',
                  icon: Icon(Icons.person, color: Colors.blueGrey),
                  initialValue: name,
                  onChanged: (val) => name = val,
                  validator: (val) =>
                  val.isEmpty ? 'Enter valid name' : null,
                )
                    : profileDataTile(
                  icon: Icon(
                    Icons.person,
                    color: Colors.blueGrey,
                  ),
                  title: 'Name',
                  value: user.name,
                ),
                isEditing
                    ? profileEditTile(
                  title: 'Block',
                  icon:
                  Icon(Icons.business, color: Colors.blueGrey),
                  onChanged: (val) => block = val,
                  initialValue: block,
                  validator: (val) =>
                  val.isEmpty ? 'Enter valid block' : null,
                )
                    : profileDataTile(
                  icon: Icon(
                    Icons.business,
                    color: Colors.blueGrey,
                  ),
                  title: 'Block',
                  value: 'Block ${user.block}',
                ),
                isEditing
                    ? profileEditTile(
                  title: 'Room',
                  icon: Icon(Icons.hotel, color: Colors.blueGrey),
                  onChanged: (val) => room = val,
                  initialValue: room,
                  validator: (val) =>
                  val.isEmpty
                      ? 'Enter valid room number'
                      : null,
                )
                    : profileDataTile(
                  icon: Icon(
                    Icons.hotel,
                    color: Colors.blueGrey,
                  ),
                  title: 'Room',
                  value: 'Room ${user.room}',
                ),
                SizedBox(
                  height: 24,
                ),
                isEditing
                    ? Container()
                    : flatButton(
                  text: 'Log out',
                  onPressed: () async {
                    Navigator.pop(context);
                    await AuthService().signOut();
                  },
                ),
                isEditing
                    ? Container()
                    : flatButton(
                  text: 'Delete account',
                  onPressed: () async {
                    Navigator.pop(context);
                    await AuthService().deleteAccount(user);
                  },
                ),
                isEditing
                    ? circleButton(
                  color: Colors.blueGrey,
                  icon: Icon(Icons.check, color: Colors.white),
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      setState(() => isLoading = true);

                      //Update the profile picture if not null
                      if (_file != null) {
                        await StorageService(
                            user: user, file: _file)
                            .uploadImage();
                      }

                      //Update the rest of the fields
                      await DatabaseService(user: user)
                          .updateUserInfo({
                        'name': name.trim(),
                        'room': room.trim(),
                        'block': block.trim()
                      });

                      Navigator.pop(context);
                    }
                  },
                )
                    : Container()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

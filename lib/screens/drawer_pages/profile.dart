import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/authenticate/sign_in.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/storage.dart';
import 'package:laundryqueue/widgets/custom_dialog.dart';
import 'package:laundryqueue/widgets/loading.dart';

class Profile extends StatefulWidget {
  final User user;
  final bool fromSignIn; //Holds whether we are here from sign in or not

  Profile({this.user, this.fromSignIn = false});

  @override
  State<StatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  User user;
  bool isEditing;
  bool isLoading;
  bool isChangingEmail;
  File _file;
  String name;
  String block;
  String room;
  String email;
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
    email = user.email;
    isEditing = widget.fromSignIn ? true : false;
    isChangingEmail = widget.fromSignIn ? true : false;
    isLoading = false;
    super.initState();
  }

  void _updateUserInfo({bool changeEmail = false}) async {
    //Display the loading the screen
    setState(() => isLoading = true);

    //By default, we re-write the email the user had
    String newEmail = user.email;

    if (changeEmail) {
      //Update email
      dynamic result = await AuthService().updateEmail(email);

      if (result is PlatformException) {
        showToast('${result.message}. All other data was updated');
      } else {
        newEmail = email; //There were no issues updating the user's email
      }
    }

    //Update the profile picture if not null
    if (_file != null) {
      await StorageService(user: user, file: _file).uploadImage();
    }

    //Update the rest of the fields
    await DatabaseService(user: user).updateUserInfo(
        {
          'name': name.trim(),
          'room': room.trim(),
          'block': block.trim(),
          'email': newEmail
        });

    Navigator.pushNamedAndRemoveUntil(
        context, '/wrapper', ModalRoute.withName(Navigator.defaultRouteName));
  }

  Widget _inputFields() {
    return Column(
      children: <Widget>[
        SizedBox(height: 16),
        isChangingEmail
            ? profileEditTile(
          title: 'Email',
          icon: Icon(
            Icons.email,
            color: Colors.blueGrey,
          ),
          initialValue: email,
          onChanged: (val) => email = val.trim(),
          validator: (val) => val.isEmpty ? 'Enter valid email' : null,
        )
            : profileDataTile(
          icon: Icon(
            Icons.email,
            color: Colors.blueGrey,
          ),
          title: 'Email',
          value: user.email,
          trailing: isEditing
              ? Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.change_history),
              onPressed: () {
                //Previously, this is where we would set isChangingEmail to true
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (context) => SignIn(isChangingEmail: true, user: user)
                    )
                );
              },
            ),
          )
              : null,
        ),
        isEditing
            ? profileEditTile(
          title: 'Name',
          icon: Icon(Icons.person, color: Colors.blueGrey),
          initialValue: name,
          onChanged: (val) => name = val.trim(),
          validator: (val) => val.isEmpty ? 'Enter valid name' : null,
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
          icon: Icon(Icons.business, color: Colors.blueGrey),
          onChanged: (val) => block = val.trim(),
          initialValue: block,
          validator: (val) => val.isEmpty ? 'Enter valid block' : null,
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
          onChanged: (val) => room = val.trim(),
          initialValue: room,
          validator: (val) =>
          val.isEmpty ? 'Enter valid room number' : null,
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
              //Have the use confirm they want to change email
              if (isChangingEmail && user.email != email) {
                showDialog(
                    context: context,
                    builder: (context) =>
                        CustomDialog(
                          title: 'Email change',
                          message:
                          'Are you sure you want to change your email address from ${user
                              .email} to $email?',
                          negativeOnTap: () {
                            Navigator.pop(context);
                            setState(() => isChangingEmail = false);
                          },
                          positiveOnTap: () {
                            Navigator.pop(context); //Remove the alert dialog
                            //Update the rest of the user information
                            _updateUserInfo(changeEmail: true,);
                          },
                          positiveButtonName: 'Yes',
                          negativeButtonName: 'No',
                        ));
              } else {
                //Just update the user information
                _updateUserInfo();
              }
            }
          },
        )
            : Container()
      ],
    );
  }

  Widget _getProfilePicture() {
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
                  fit: BoxFit.fill, image: NetworkImage(snapshot.data),),),
            );
          }

          return Container();
        });

    return Container(
      width: 140,
      height: 140,
      child: Stack(
        children: <Widget>[
          isEditing
              ? _file != null
              ? CircleAvatar(
            radius: 65,
            backgroundImage: FileImage(_file),
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

  Widget _getPortraitWidget() {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[_getProfilePicture(), _inputFields()],
        ),
      ),
    );
  }

  Widget _getLandscapeWidget() {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Center(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _getProfilePicture(),
                      SizedBox(height: 32),
                    ]
                )
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(bottom: 16, right: 16),
                child: _inputFields(),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPortrait =
        MediaQuery
            .of(context)
            .orientation == Orientation.portrait;

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
            if(widget.fromSignIn) {
              Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
            } else {
              Navigator.pop(context);
            }
          }
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
      body: Form(
          key: _formKey,
          child: isPortrait ? _getPortraitWidget() : _getLandscapeWidget(),
        ),
    );
  }
}

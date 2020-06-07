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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.0),
                  image: DecorationImage(
                      fit: BoxFit.fill, image: NetworkImage(snapshot.data))),
            );
          }

          return Container();
        });

    return Container(
      constraints: BoxConstraints(maxHeight: 100),
      child: Stack(
        children: <Widget>[
          isEditing
              ? _file != null
                  ? Container(
                      width: 90,
                      height: 90,
                      child: Image.file(_file),
                    )
                  : profilePicture
              : profilePicture,
          isEditing
              ? Container(
                  // Is it only restricted to the height + width of the container
                  width: 90,
                  height: 90,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: InkResponse(
                      onTap: _pickImage,
                      child: Container(
                        width: 40,
                        height: 40,
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
                  Navigator.pop(context);
                },
              ),
              title: Text('Account', style: TextStyle(color: Colors.black)),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 48.0),
                  child: isEditing
                      ? Container()
                      : GestureDetector(
                          child: Icon(Icons.edit, color: Colors.black),
                          onTap: () {
                            setState(() => isEditing = true);
                          }),
                )
              ],
            ),
            body: Container(
              padding: EdgeInsets.all(16),
              child: Stack(children: <Widget>[
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          getProfilePicture(),
                          isEditing
                              ? Container(
                                  padding: EdgeInsets.only(left: 8.0),
                                  width: 150,
                                  child: TextFormField(
                                    onChanged: (val) => name = val,
                                    validator: (val) =>
                                        val.isEmpty ? 'Enter valid name' : null,
                                    decoration: editProfileInputDecoration
                                        .copyWith(hintText: 'Name'),
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.only(left: 8.0),
                                  width: 150,
                                  child: Text(
                                    user.name,
                                    style: TextStyle(fontSize: 18),
                                  ))
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.email),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text('${user.email}'),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: isEditing
                            ? Container(
                                width: 150,
                                child: TextFormField(
                                  onChanged: (val) => block = val,
                                  validator: (val) => val.isEmpty
                                      ? 'Enter valid block number'
                                      : null,
                                  decoration:
                                      editProfileInputDecoration.copyWith(
                                          icon: Icon(Icons.business),
                                          hintText: 'Block'),
                                ),
                              )
                            : Row(children: <Widget>[
                                Icon(Icons.business),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text('Block ${user.block}'),
                                )
                              ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: isEditing
                            ? Container(
                                width: 150,
                                child: TextFormField(
                                  onChanged: (val) => room = val,
                                  validator: (val) => val.isEmpty
                                      ? 'Enter valid room number'
                                      : null,
                                  decoration:
                                      editProfileInputDecoration.copyWith(
                                          icon: Icon(Icons.hotel),
                                          hintText: 'Room'),
                                ),
                              )
                            : Row(children: <Widget>[
                                Icon(Icons.hotel),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text('Room ${user.room}'),
                                )
                              ]),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: isEditing
                      ? Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.check, color: Colors.white),
                            onPressed: () async {
                              if (_formKey.currentState.validate()) {
                                setState(() => isLoading = true);

                                //Update the profile picture if not null
                                if (_file != null) {
                                  await StorageService(user: user, file: _file)
                                      .uploadImage();
                                }

                                //Update the rest of the fields
                                await DatabaseService(user: user)
                                    .updateUserInfo({
                                  'name': name,
                                  'room': room,
                                  'block': block
                                });

                                Navigator.pop(context);
                              }
                            },
                          ))
                      : Container(
                          height: 100,
                          child: Column(
                            children: <Widget>[
                              Container(
                                height: 1,
                                color: Colors.grey,
                              ),
                              FlatButton(
                                child: Text('Log out'),
                                onPressed: () async {
                                  //TODO: Fix issue where .setState() / .markNeedsBuild() is said to be called at the wrong time
                                  Navigator.pop(context);
                                  await AuthService().signOut();
                                },
                              ),
                              FlatButton(
                                child: Text('Delete account'),
                                onPressed: () async {
                                  //TODO: Fix issue where .setState() / .markNeedsBuild() is said to be called at the wrong time
                                  Navigator.pop(context);
                                  await AuthService().deleteAccount(user);
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ]),
            ),
          );
  }
}

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/widgets/loading.dart';

class Register extends StatefulWidget {
  final Function toggle;
  final Function toggleWrapper;

  Register({this.toggle, this.toggleWrapper});

  @override
  State<StatefulWidget> createState() => RegisterState();
}

class RegisterState extends State<Register> {
  String name;
  String block;
  String lpcEmail;
  String room;
  String password;
  File _file;

  AuthService _auth = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool loading = false;

  Future _pickImage() async {
    var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _file = imageFile;
    });
  }

  Widget getImageSelector() {
    return Container(
      constraints: BoxConstraints(maxHeight: 85),
      child: Stack(
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.0)),
            child: _file != null
                ? Image.file(
                  _file,
                  fit: BoxFit.fill,
                )
                : CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                  ),
          ),
          Container(
            // Is it only restricted to the height + width of the container
            width: 80,
            height: 80,
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.brown[100],
            body: Container(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          getImageSelector(),
                          Container(
                            padding: EdgeInsets.only(left: 8.0),
                            constraints: BoxConstraints(maxWidth: 150),
                            child: TextFormField(
                                validator: (value) =>
                                    value.isEmpty ? "Enter a valid name" : null,
                                onChanged: (newString) =>
                                    name = newString.trim(),
                                decoration: InputDecoration.collapsed(
                                  hintText: "Name",
                                )),
                          )
                        ],
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                          onChanged: (newString) => lpcEmail = newString.trim(),
                          decoration: createAccountInputDecoration.copyWith(
                              hintText: "Email address",
                              icon: Icon(Icons.email)),
                          validator: (value) => value.isEmpty
                              ? "Enter a valid email address"
                              : null),
                      SizedBox(height: 16),
                      TextFormField(
                        obscureText: true,
                        onChanged: (newString) => password = newString.trim(),
                        decoration: createAccountInputDecoration.copyWith(
                            hintText: "Password", icon: Icon(Icons.security)),
                        validator: (value) =>
                            value.isEmpty ? "Enter a valid password" : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        onChanged: (newString) => block = newString.trim(),
                        decoration: createAccountInputDecoration.copyWith(
                            hintText: "Block", icon: Icon(Icons.business)),
                        validator: (value) =>
                            value.isEmpty ? "Entere a block number" : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                          onChanged: (newString) => room = newString.trim(),
                          decoration: createAccountInputDecoration.copyWith(
                              hintText: "Room", icon: Icon(Icons.hotel)),
                          validator: (value) =>
                              value.isEmpty ? "Enter a room number" : null),
                      SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: () async {
                              if (_formKey.currentState.validate()) {
                                if (_file != null) {
                                  setState(() => loading = true);

                                  dynamic result =
                                      await _auth.registerWithEmailAndPassword(
                                          block: block,
                                          name: name,
                                          room: room,
                                          email: lpcEmail,
                                          file: _file,
                                          password: password);

                                  if (result is PlatformException) {
                                    setState(() => loading = false);
                                    Scaffold.of(context).showSnackBar(
                                      SnackBar(
                                        duration: Duration(seconds: 3),
                                        content:
                                            Text("Error: ${result.message}"),
                                      ),
                                    );
                                  } else if (result == null) {
                                    setState(() => loading = false);
                                    Scaffold.of(context).showSnackBar(
                                      SnackBar(
                                        duration: Duration(seconds: 3),
                                        content: Text(
                                            "Unknown error signing up. Please try again"),
                                      ),
                                    );
                                  }

                                  //Set up default SharedPreferences values
                                  await Preferences.setDefaultPreferences();
                                  widget.toggleWrapper();
                                } else {
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                      content: Text('Select an image')));
                                }
                              }
                            },
                            child: Container(
                                width: 100,
                                height: 50,
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.pink,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                ),
                                child: Center(
                                  child: Text("START", style: TextStyle()),
                                ) // Find out how to make text be all caps
                                ),
                          ),
                          FlatButton(
                            child: Text("Sign in"),
                            onPressed: widget.toggle,
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          );
  }
}

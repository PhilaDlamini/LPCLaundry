import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/widgets/loading.dart';
import 'package:laundryqueue/widgets/progress.dart';

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

  void _start() async {
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
                content: Text("Error: ${result.message}"),
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
          Scaffold.of(context).showSnackBar(
              SnackBar(content: Text('Select an image')));
        }
      }
  }

  Widget _getInputFields() {
    return Column(
      children: <Widget>[
        textFormField('Email',
          onChanged: (val) => lpcEmail = val.trim(),
          validator: (text) =>
          text.isEmpty ? 'Enter valid email' : null,
        ),
        textFormField('Password',
            onChanged: (val) => password = val.trim(),
            validator: (text) =>
            text.isEmpty ? 'Enter valid password' : null,
            obscureText: true),
        textFormField(
          'Block',
          onChanged: (val) => block = val.trim(),
          validator: (text) =>
          text.isEmpty ? 'Enter valid block' : null,
        ),
        textFormField('Room',
          onChanged: (val) => room = val.trim(),
          validator: (text) =>
          text.isEmpty ? 'Eneter valid room' : null,),
      ],
    );
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
             border: Border.all(
               color: Colors.white,
               width: 1,
             )
           ),
           child:_file == null ? CircleAvatar(
             backgroundColor: Colors.white,) :
             CircleAvatar(backgroundImage: FileImage(_file),
             )
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
                    color: Colors.greenAccent
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
          ), // For the image image picker
        ],
      ),
    );
  }

  Widget _portraitWidget(double height, double width) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 42, left: 16),
          child: Row(
            children: <Widget>[
              getImageSelector(),
              Container(
                padding: EdgeInsets.only(left: 8.0),
                constraints: BoxConstraints(maxWidth: 150),
                child: TextFormField(
                    validator: (value) =>
                    value.isEmpty ? "Enter a valid name" : null,
                    onChanged: (newString) => name = newString.trim(),
                    decoration: InputDecoration.collapsed(
                        hintText: "Name",
                        hintStyle: TextStyle(fontSize: 15)
                    )),
              )
            ],
          ),
        ),
        Container(
          height: height - 152,
          width: width,
          margin: EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16))),
          child: Column(children: <Widget>[
            _getInputFields(),
            Container(
              width: 175,
              margin: EdgeInsets.only(top: 32),
              child: Row(children: <Widget>[
                roundedButton(
                  onTapped: _start,
                  text: 'Sign up',
                ),
                FlatButton(
                  child: Text('Log in'),
                  onPressed: widget.toggle,
                  splashColor: Colors.yellow[100],
                ),
              ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _landscapeWidget(double height, double width) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Column(
            children: <Widget> [
              getImageSelector(),
          Container(
                    padding: EdgeInsets.only(left: 8.0),
                    constraints: BoxConstraints(maxWidth: 150),
                    child: TextFormField(
                      textAlign: TextAlign.center,
                        validator: (value) =>
                        value.isEmpty ? "Enter a valid name" : null,
                        onChanged: (newString) => name = newString.trim(),
                        decoration: InputDecoration.collapsed(
                            hintText: "Name",
                            hintStyle: TextStyle(fontSize: 15)
                        )),
                  ),
              Container(
                width: 175,
                margin: EdgeInsets.only(top: 32),
                child: Row(children: <Widget>[
                  roundedButton(
                    color: Colors.white70,
                    onTapped: _start,
                    text: 'Start',
                  ),
                  FlatButton(
                    child: Text('Sign in'),
                    onPressed: widget.toggle,
                    splashColor: Colors.yellow[100],
                  ),
                ],
                ),
              ),

          ]),
        ),
        Expanded(
          flex: 1,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), topLeft: Radius.circular(16)),
              color: Colors.white
            ),
            child: SingleChildScrollView(
              child: _getInputFields(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    bool isPortrait = mediaQueryData.orientation == Orientation.portrait;
    double height = mediaQueryData.size.height;
    double width = mediaQueryData.size.width;

    return loading
        ? Progress(message: 'Setting you up')
        : Scaffold(
            backgroundColor: Colors.yellow,
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: isPortrait ? _portraitWidget(height, width) : _landscapeWidget(height, width),
              )
            ),
    );
  }
}

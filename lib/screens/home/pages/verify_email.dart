import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/streams/count_down.dart';

class VerifyEmail extends StatefulWidget {
  final User user;
  final Function toggle;
  final FirebaseUser firebaseUser;

  VerifyEmail({this.user, this.firebaseUser, this.toggle});

  @override
  State<StatefulWidget> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  Function onResendTap; //Implement later

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('Verify email'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: FutureBuilder(
            future: AuthService().sendVerificationEmail(widget.firebaseUser),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: Text(
                    'Sending email verification',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              if (snapshot.data is Exception) {
                return Center(
                    child: Container(
                  height: 300,
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.error_outline,
                        color: Colors.grey[700],
                        size: 30,
                      ),
                      Text(snapshot.data.toString()),
                    ],
                  ),
                ),
                );
              }

                return Center(
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 300,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.email,
                                size: 30,
                                color: Colors.yellow[700],
                              ),
                              Text(
                                'An email has been sent to ${widget.user.email} '
                                'Log in and click on the link provided to verify your email',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
//                              StreamBuilder( //TODO: In future, fix these which allow for resending the email
//                                  stream: CountDown(
//                                    duration: Duration(seconds: 90),
//                                  ).stream,
//                                  builder: (context, snapshot) {
//                                    if (snapshot.hasData) {
//                                      String data = snapshot.data.trim();
//                                      if (data == '0s') {
//                                        Timer.run(() {
//                                          setState(() {
//                                            onResendTap = () {
//                                              Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
//                                            };
//                                          });
//                                        });
//                                      }
//
//                                      return Padding(
//                                        padding:
//                                            const EdgeInsets.only(top: 16.0),
//                                        child: Text(
//                                          data == '0s'
//                                              ? 'To re-send this email, click the button below'
//                                              : 'You will be able to re-send this email in'
//                                                  '\n${snapshot.data}',
//                                          textAlign: TextAlign.center,
//                                          style: TextStyle(
//                                            fontSize: 16,
//                                          ),
//                                        ),
//                                      );
//                                    }
//
//                                    return Container();
//                                  }),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: RaisedButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(16),
                            ),
                          ),
                          color: Colors.blueGrey,
                          textColor: Colors.white,
                          child: Text('Refresh'),
                          onPressed: () {
                            widget.toggle();
                          },
                        ),
                      )
                    ],
                  ),
                );

            }),
      ),
    );
  }
}

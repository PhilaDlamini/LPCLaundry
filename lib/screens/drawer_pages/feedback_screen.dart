import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class FeedbackScreen extends StatefulWidget {
  final User user;

  FeedbackScreen({this.user});

  @override
  State<StatefulWidget> createState() => _FeedbackScreenState();

}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String subject;
  String emailBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: GestureDetector(
              child: Icon(Icons.clear),
              onTap: () {
                Navigator.pop(context);
              }
          ),
          title: Text('Feedback'),
          actions: <Widget>[
            popupMenuButton(context, user: widget.user)
          ],
        ),
        body: SingleChildScrollView(child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
                children: <Widget>[
                  Card(
                    color: Colors.yellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          child: Column(
                              children: <Widget>[
                                Container(
                                  child: feedbackTextInput(
                                    validator: (val) =>
                                    val.isEmpty
                                        ? 'Enter a valid subject'
                                        : null,
                                    hintText: 'Subject',
                                    height: 40,
                                    onChanged: (value) => subject = value.trim(),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 16),
                                  child: feedbackTextInput(
                                    validator: (val) =>
                                    val.isEmpty
                                        ? 'Enter valid feedback'
                                        : null,
                                    hintText: 'Feedback',
                                    onChanged: (value) =>
                                    emailBody = value.trim(),
                                    height: 290,
                                  ),
                                ),
                              ]
                          ),
                        ),
                      )
                  ),
                  SizedBox(height: 32),
                  circleButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    color: Colors.blueGrey[300],
                    onPressed: () async {
                      if(_formKey.currentState.validate()) {
                        final Email email = Email(
                          subject: subject,
                          body: emailBody,
                          recipients: ['phila.nkosi@imaginescholar.org'],
                          isHTML: false
                        );

                        await FlutterEmailSender.send(email);
                      }
                    }
                  )
                ]
              )
          ),
        )
    );
  }

}
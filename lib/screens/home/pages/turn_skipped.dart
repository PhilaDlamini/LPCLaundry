import 'package:flutter/material.dart';

class TurnSkipped extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Column(
            children: <Widget>[
              Text('Your turn in the queue was skipped'),
              Text('Your next turn is at 13:00'),
              RaisedButton(
                child: Text('Ok'),
                onPressed: () {
                  //Go back to the home page
                }
              )
            ],
          ),
        ),
      ),
    );
  }

}
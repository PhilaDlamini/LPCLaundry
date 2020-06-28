import 'package:flutter/material.dart';

class Progress extends StatelessWidget{
  final String message;

  Progress({this.message});

  @override
  Widget build(context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          height: 100,
          child: Column(
            children: <Widget> [
              Container(
                width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[600])
                  ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(this.message, style: TextStyle(fontSize: 17, color: Colors.blueGrey[900], fontWeight: FontWeight.w800)),
              ),
            ]
          ),
        )
      )
    );
  }
}
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatelessWidget {
  final bool longDuration;
  final List<String> phrases = [
    'Smile :)',
    'You look nice :)',

  ];

  Loading({this.longDuration = false});

  String phrase() => phrases[Random().nextInt(phrases.length)];

  @override
  Widget build(BuildContext context) {
    return longDuration
        ? Scaffold(
          body: Container(
              color: Colors.white,
              child: Center(
                child: Container(
                  height: 150,
                  child: Column(
                    children: <Widget>[
                      SpinKitChasingDots(
                        size: 80,
                        color: Colors.yellow[700],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(phrase(),
                            style: TextStyle(
                                fontSize: 17,
                                color: Colors.blueGrey[900],
                                fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        )
        : Container(
            color: Colors.yellow,
            child: Center(
              child: SpinKitPulse(color: Colors.white, size: 100.0),
            ),
          );
  }
}

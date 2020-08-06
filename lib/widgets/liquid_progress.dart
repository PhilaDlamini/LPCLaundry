import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';

class LiquidProgress extends StatelessWidget {
  final double value;

  LiquidProgress({this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Stack(
        children: <Widget>[
          LiquidLinearProgressIndicator(
            value: value,
            direction: Axis.vertical,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
          ),
        ],
      ),
    );
  }
}

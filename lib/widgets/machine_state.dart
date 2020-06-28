import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MachineState extends StatefulWidget {
  final bool isRunning;

  MachineState({this.isRunning});

  @override
  State<StatefulWidget> createState() => _MachineStateState();
}

class _MachineStateState extends State<MachineState> with SingleTickerProviderStateMixin{

  bool isRunning;
  AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    //When rebuilding, we want to use the new updated value
    isRunning = widget.isRunning;

    return isRunning ? Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blueGrey, Colors.greenAccent]
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: RotationTransition(
          turns: _animationController,
          alignment: Alignment.centerLeft,
          child: Container(
            width: 25,
            height: 10,
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: Colors.white
              ),
              borderRadius: BorderRadius.all(Radius.circular(16))
            ),
          ),
        )
      ),
    ) : Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300]
      ),
      child: Icon(Icons.error_outline, color: Colors.grey[600],),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

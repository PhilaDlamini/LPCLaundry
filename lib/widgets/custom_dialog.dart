import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/streams/count_down.dart';

class CustomDialog extends StatefulWidget {
  final String title;
  final String message;
  final String negativeButtonName;
  final String positiveButtonName;
  final Function positiveOnTap;
  final Function negativeOnTap;
  final Function extendTime;
  final bool showTimer;
  final bool radioButton;
  final int secondsLeft;
  final List<String> timeExtensions = [
    '1 minutes',
    '5 minutes',
    '10 minutes',
    '20 minutes',
    '40 minutes',
    '60 minutes'
  ];

  CustomDialog(
      {this.title,
      this.radioButton = false,
      this.showTimer = false,
      this.negativeOnTap,
      this.secondsLeft,
      this.extendTime,
      this.message,
      this.positiveButtonName,
      this.negativeButtonName,
      this.positiveOnTap});

  @override
  State<StatefulWidget> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  String currentlySelectedRadio;

  Widget dialogContent() {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min, //Makes the card compact
      children: <Widget>[
        Text(
          widget.title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        SizedBox(
          height: 16,
        ),
        widget.radioButton
            ? Column(
                children: widget.timeExtensions.map((item) {
                  return RadioListTile(
                    value: item,
                    title: Text(item),
                    groupValue: currentlySelectedRadio,
                    onChanged: (val) {
                      currentlySelectedRadio = val;
                      setState(() {});
                    },
                  );
                }).toList(),
              )
            : Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
        SizedBox(
          height: 24,
        ),
        Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: widget.showTimer ? 100 : 80,
                  child: flatButton(
                    text: widget.negativeButtonName,
                    onPressed: widget.negativeOnTap != null
                        ? widget.negativeOnTap
                        : () {
                            Navigator.pop(context);
                          },
                  ),
                ),
                Container(
                  width: widget.showTimer ? 90 : 80,
                  child: flatButton(
                    text: widget.positiveButtonName,
                    onPressed: widget.radioButton
                        ? () async {
                            Duration timeExtension = Duration(
                                minutes: int.parse(
                                    currentlySelectedRadio.split(' ')[0]));

                            await widget.extendTime(timeExtension);
                          }
                        : widget.positiveOnTap,
                  ),
                ),
              ],
            ))
      ],
    );
    return widget.showTimer
        ? Stack(
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(top: 56),
                  padding:
                      EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    color: Colors.white,
                  ),
                  child: content),
              Positioned(
                left: 1,
                right: 1,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueGrey[600],
                  child: StreamBuilder(
                      stream: CountDown(
                              duration: Duration(seconds: widget.secondsLeft))
                          .stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          //Remove the alert dialog when we get to zero (at his point too, the isolate will skip the user)
                          if (snapshot.data.trim() == '0s') {
                            Timer.run(() => Navigator.pop(context));
                          }

                          return Center(
                            child: Text(
                              '${snapshot.data}',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          );
                        }

                        return Container();
                      }),
                ),
              ),
            ],
          )
        : Container(
            padding: EdgeInsets.all(16),
            child: content,
          );
  }

  @override
  void initState() {
    currentlySelectedRadio = widget.timeExtensions[0];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      backgroundColor: widget.showTimer ? Colors.transparent : Colors.white,
      elevation: 0,
      child: Container(
        width: 350,
        child: SingleChildScrollView(
          child: dialogContent(),
        ),
      ),
    );
  }
}

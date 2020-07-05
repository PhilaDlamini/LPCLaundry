import 'package:flutter/material.dart';

class Disconnected extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('Disconnected'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.signal_wifi_off,
                color: Colors.blueGrey[400],
                size: 70,
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                'You are not connected to any wifi or mobile networks. Connect to a network to continue using Laundry',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.blueGrey[800]),
              ),
              SizedBox(
                height: 50,
              )
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/inherited_widgets/user_inherited_widget.dart';
import 'package:laundryqueue/screens/home/pages/queue_page.dart';

class StartQueuing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 100),
          child: Column(
            children: <Widget> [
              Text('This is the main queue screen'),
              RaisedButton(
                child: Text('Queue'),
                onPressed: () {
                    Navigator.push(context,
                    MaterialPageRoute(
                      builder: (context) => QueuePage(),
                      settings: RouteSettings(
                        arguments: UserInheritedWidget.of(context).user
                      )
                    ));
                },
              )
            ]
          ),
        ),
    );
  }

}
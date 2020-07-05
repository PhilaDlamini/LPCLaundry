import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class Info extends StatelessWidget {
  final User user;
  final bool isFirstTime;

  Info({this.user, this.isFirstTime = false});

  Widget infoItem(String title, String info, Widget trailing, {double width = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        elevation: 2,
        child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.all(0),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18
                    ),
                  ),
                  trailing: Container(
                    width: width,
                    child: trailing,
                  ),
                ),
                Text(
                  info,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    List infoCards = [
      infoItem(
          'Queuing',
          'To queue for either a washer, drier, or both, click the queue button in your home screen'
              '\n\nYou will either be queued five minutes from now, or five minutes from the last person, depending on availability in the queue. '
              'This five minute leeway applies to all who enter the queue and helps you get to the laundry room in time to start using the machine',
          infoQueueButton(),
          width: 65
      ),
      infoItem(
        'Queuing jointly',
        'When queuing, you can choose to queue with others, or queue alone. This joint queue option helps you save water by combining your clothes'
            ' with someone else if you have few things to wash and/or dry',
        Container(),
      ),
      infoItem(
          'Extending time',
          'If the initial duration you selected is not enough to finish washing/drying your clothes, you can request for a time extension',
          infoExtendButton(),
          width: 30
      ),
      infoItem(
          'Machines',
          'You can see all the machines in your block, including which ones are working and which ones are not. You also have the option to disable or enable a machine depending'
              ' on whether it is working or not',
          Icon(Icons.card_membership, color: Colors.yellow[600],),
          width: 24
      ),
     isFirstTime ? roundedButton(
       color: Colors.blueGrey,
       text: 'OK',
       onPressed: () async {
         await Preferences.updateBoolData(Preferences.FIRST_TIME_LOGGED_IN, false);
         Navigator.pop(context);
       }
     ) : Container()
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blueGrey[200], Colors.blueGrey[100], Colors.white]
            )
        ),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: isFirstTime ? null:
              GestureDetector(
                child: Icon(Icons.clear),
                onTap: () {
                  Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
                },
              ),
              elevation: 0,
              title: Padding(
                padding: EdgeInsets.only(left: isFirstTime ? 8 : 0),
                child: Text('Information'),
              ),
              actions: <Widget>[
                popupMenuButton(context, user: user),
              ],
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return infoCards[index];
                  },
                childCount: infoCards.length
              ),
            )
          ],
        ),
      )
    );
  }
}

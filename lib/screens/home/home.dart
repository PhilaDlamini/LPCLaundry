import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/inherited_widgets/user_inherited_widget.dart';
import 'package:laundryqueue/models/Queue.dart';
import 'package:laundryqueue/models/QueueData.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/home/pages/queued.dart';
import 'package:laundryqueue/screens/home/pages/start_queuing.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/streams/queue_stream.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    User user = UserInheritedWidget.of(context).user;

    return Scaffold(
      drawer: Drawer(
        child: Column(children: <Widget>[
          DrawerHeader(
            child: Container(
              color: Colors.red[100],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Setting'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
              leading: Icon(Icons.info),
              title: Text('Info'),
              onTap: () {
                // Navigator.pushNamed(context, '/settings');
              }),
          ListTile(),
        ]),
      ),
      body: StreamBuilder(
          stream: QueueStream(
                  user: user,
                  queueDataStreams: DatabaseService(
                      user: user,
                      availableDriers: ['1', '2'],
                      availableWashers: ['1', '2', '3']).getQueueDataStreams())
              .queueStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<QueueData> queueListData = snapshot.data;

              //Get the queueData instances where the user is queued
              QueueData washerQueueData = queueListData.singleWhere(
                  (item) => item.whichMachine == 'washer' && item.userQueued,
                  orElse: () => null);
              QueueData drierQueueData = queueListData.singleWhere(
                  (item) => item.whichMachine == 'drier' && item.userQueued,
                  orElse: () => null);

              //Check if the user is queued for either drier or washer
              if (washerQueueData != null && drierQueueData != null) {
                return QueuedList(
                    washerQueueData: washerQueueData,
                    drierQueueData: drierQueueData);
              } else if (washerQueueData != null) {
                return QueuedList(washerQueueData: washerQueueData);
              } else if (drierQueueData != null) {
                return QueuedList(drierQueueData: drierQueueData);
              }

              //Else, the user is not queued in anything
              return StartQueuing();
            }

            return Container();
          }),
    );
  }
}

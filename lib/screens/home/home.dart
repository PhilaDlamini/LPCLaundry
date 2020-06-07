import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/drawer_pages/profile.dart';
import 'package:laundryqueue/screens/home/pages/queued.dart';
import 'package:laundryqueue/screens/home/pages/start_queuing.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/streams/queue_stream.dart';
import 'package:laundryqueue/widgets/loading.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> {

  @override
  Widget build(BuildContext context) {
    User user = DataInheritedWidget.of(context).user;

    return Scaffold(
      drawer: Drawer(
        child: Column(children: <Widget>[
          DrawerHeader(
            child: Container(
              color: Colors.red[100],
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Account'),
            onTap: () {
              Navigator.push(context,
              MaterialPageRoute(
                builder: (context) => Profile(user: user)
              ));
            },
          ),
          Container(
            color: Colors.blueGrey,
            height: 1,
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
                  context,
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

                //Refresh data if not up to date
                return FutureBuilder(
                  future: DatabaseService(location: 'Block ${user.block}').refreshQueueLists(
                      washerMachineNumber: washerQueueData.machineNumber,
                    drierMachineNumber: drierQueueData.machineNumber
                  ),
                  builder: (context, snapshot) {

                    if(!snapshot.hasData) {
                      return Loading();
                    }

                    return DataInheritedWidget(
                      queueDataList: queueListData,
                      user: user,
                      child: Queued(
                          washerQueueData: washerQueueData,
                          drierQueueData: drierQueueData),
                    );
                  },
                );
              } else if (washerQueueData != null) {

                //Refresh data if not up to date
                return FutureBuilder(
                  future: DatabaseService(location: 'Block ${user.block}').refreshQueueLists(
                      washerMachineNumber: washerQueueData.machineNumber),
                  builder: (context, snapshot) {

                    if(!snapshot.hasData) {
                      return Loading();
                    }

                    return DataInheritedWidget(
                      queueDataList: queueListData,
                      user: user,
                      child: Queued(washerQueueData: washerQueueData),
                    );
                  },
                );
              } else if (drierQueueData != null) {

                //Refresh data if it is old
                return FutureBuilder(
                  future: DatabaseService(
                    location: 'Block ${user.block}').refreshQueueLists(
                      drierMachineNumber: drierQueueData.machineNumber
                  ),
                  builder: (context, snapshot) {
                    if(snapshot.hasData) {
                      return DataInheritedWidget(
                        queueDataList: queueListData,
                        user: user,
                        child: Queued(drierQueueData: drierQueueData),
                      );
                    }

                    return Loading();
                  },
                );
              }

              //Else, the user is not queued in anything
              return StartQueuing(user: user);
            }

            return Container();
          }),
    );
  }

}

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/inherited_widgets/data_inherited_widget.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/screens/drawer_pages/info.dart';
import 'package:laundryqueue/screens/drawer_pages/machines.dart';
import 'package:laundryqueue/screens/drawer_pages/profile.dart';
import 'package:laundryqueue/screens/drawer_pages/settings.dart';
import 'package:laundryqueue/screens/drawer_pages/feedback_screen.dart';
import 'package:laundryqueue/screens/home/pages/queued.dart';
import 'package:laundryqueue/screens/home/pages/start_queuing.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/storage.dart';
import 'package:laundryqueue/streams/queue_stream.dart';
import 'package:laundryqueue/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> {
  Map<String, dynamic> machines;
  User user;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    user = DataInheritedWidget.of(context).user;
    machines = DataInheritedWidget.of(context).machines;

    return Scaffold(
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.yellow),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.topLeft,
                    child: FutureBuilder(
                      future: StorageService(user: user).getImageURL(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            width: 70,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                            ),
                          );
                        }

                        return Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: NetworkImage(snapshot.data))),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 8),
                      child: Text(user.name,
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('Block ${user.block}/${user.room}',
                            style: TextStyle(fontSize: 14)),
                      ))
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: Colors.yellow[600]),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Profile(user: user)));
              },
            ),
            ListTile(
              leading: Icon(Icons.card_membership, color: Colors.yellow[600]),
              title: Text('Machines'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Machines(user: user)));
              },
            ),
            ListTile(
              leading: Icon(Icons.message, color: Colors.yellow[600]),
              title: Text('Feedback'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FeedbackScreen(user: user)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.yellow[600]),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings(user: user)),
                );
              },
            ),
            ListTile(
                leading: Icon(Icons.info, color: Colors.yellow[600]),
                title: Text('Info'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Info(user: user)),
                  );
                }),
            ListTile(),
          ]),
        ),
      ),
      body: StreamBuilder(
        stream: QueueStream(context,
                user: user,
                queueDataStreams: DatabaseService(
                        user: user,
                        availableDriers: machines['driers'],
                        availableWashers: machines['washers'])
                    .getQueueDataStreams())
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
                future: DatabaseService(location: 'Block ${user.block}')
                    .refreshQueueLists(
                        washerMachineNumber: washerQueueData.machineNumber,
                        drierMachineNumber: drierQueueData.machineNumber),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
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
                future: DatabaseService(location: 'Block ${user.block}')
                    .refreshQueueLists(
                        washerMachineNumber: washerQueueData.machineNumber),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
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
                future: DatabaseService(location: 'Block ${user.block}')
                    .refreshQueueLists(
                        drierMachineNumber: drierQueueData.machineNumber),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
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
            return StartQueuing(
              user: user,
              availableMachines: machines,
            );
          }

          return Container();
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/widgets/placeholder_list_item.dart';
import 'package:laundryqueue/widgets/user_item.dart';
import 'package:laundryqueue/screens/home/pages/queue_page.dart';
import 'package:laundryqueue/constants/constants.dart';

class ChooseUsers extends StatefulWidget {
  final User user;
  final bool isDrying;
  final bool isWashing;
  final Map<String, dynamic> availableMachines;
  final QueueInstance washerQueueInstance;

  ChooseUsers(
      {this.user,
      this.washerQueueInstance,
      this.isWashing = true,
      this.isDrying = true,
      this.availableMachines});

  @override
  State<StatefulWidget> createState() => _ChooseUsersState();
}

class _ChooseUsersState extends State<ChooseUsers> {
  User user;
  List<User> selectedUsers = List<User>();

  @override
  void initState() {
    user = widget.user;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isLandScape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        elevation: 0,
        title: Text('Choose', style: TextStyle(color: Colors.black)),
        leading: GestureDetector(
          child: Icon(Icons.clear, color: Colors.black),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[],
      ),
      body: Container(
        margin: EdgeInsets.all(16),
        child: Column(children: <Widget>[
          Expanded(
            flex: 1,
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              child: Container(
                padding: EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text('Queue with'),
                    ),
                    Expanded(
                      flex: 1,
                      child: FutureBuilder(
                          future: DatabaseService(user: user).getUsersInBlock(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              if (isLandScape) {
                                return GridView.count(
                                  crossAxisSpacing: 16,
                                  crossAxisCount: 2,
                                  children: List.generate(5, (index) => PlaceHolderListItem()),
                                );
                              }


                              return ListView(
                                children: List.generate(
                                    5, (index) => PlaceHolderListItem()),
                              );
                            }

                            if (snapshot.data is String) {
                              return Center(
                                child: Container(
                                  height: 50,
                                  child: Column(
                                    children: <Widget>[
                                      Icon(Icons.people),
                                      Text(snapshot.data)
                                    ],
                                  ),
                                ),
                              );
                            }
                            List<User> usersInBlock = snapshot.data;

                            if (isLandScape) {
                              return GridView.count(
                                crossAxisSpacing: 16,
                                crossAxisCount: 2,
                                children: usersInBlock.map((item) {
                                  return UserItem(
                                    user: item,
                                    onUserSelected: () {
                                      selectedUsers.add(item);
                                    },
                                    onUserUnSelected: () {
                                      selectedUsers.remove(item);
                                    },
                                  );
                                }).toList(),
                              );
                            }

                            return ListView.builder(
                                itemCount: usersInBlock.length,
                                itemBuilder: (context, index) {
                                  return UserItem(
                                    user: usersInBlock[index],
                                    onUserSelected: () {
                                      selectedUsers.add(usersInBlock[index]);
                                    },
                                    onUserUnSelected: () {
                                      selectedUsers.remove(usersInBlock[index]);
                                    },
                                  );
                                });
                          }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 100,
              margin: EdgeInsets.only(top: 16),
              child: roundedButton(
                text: 'Queue',
                color: Colors.white,
                onTapped: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => QueuePage(
                            isWashing: widget.isWashing,
                            isDrying: widget.isDrying,
                            washerQueueInstance: widget.washerQueueInstance,
                            usersQueuingWith: selectedUsers,
                            availableMachines: widget.availableMachines),
                        settings: RouteSettings(arguments: user)),
                  );
                },
              ),
            ),
          )
        ]),
      ),
    );
  }
}

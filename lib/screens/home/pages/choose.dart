import 'package:flutter/material.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/widgets/list_item.dart';
import 'package:laundryqueue/screens/home/pages/queue_page.dart';
import 'package:laundryqueue/constants/constants.dart';

class ChooseUsers extends StatefulWidget {
  final User user;
  final bool isDrying;
  final bool isWashing;
  final QueueInstance washerQueueInstance;

  ChooseUsers({this.user, this.washerQueueInstance, this.isWashing = true, this.isDrying = true});

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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          child: Icon(Icons.clear, color: Colors.black),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            RaisedButton(
                child: Text('Solo'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => QueuePage(
                              isWashing: widget.isWashing,
                              isDrying: widget.isDrying,
                              washerQueueInstance: widget.washerQueueInstance,
                              usersQueuingWith: [],
                            ),
                        settings: RouteSettings(arguments: user)),
                  );
                }),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text('OR choose who to queue with'),
            ),
            Expanded(
              flex: 1,
              child: Stack(children: <Widget>[
                FutureBuilder(
                    future: DatabaseService(user: user).getUsersInBlock(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data is String) {
                          return Text(snapshot.data);
                        }
                        List<User> usersInBlock = snapshot.data;
                        return ListView.builder(
                            itemCount: usersInBlock.length,
                            itemBuilder: (context, index) {
                              return ListItem(
                                selectUserMode: true,
                                user: usersInBlock[index],
                                onUserSelected: () {
                                  selectedUsers.add(usersInBlock[index]);
                                },
                                onUserUnSelected: () {
                                  selectedUsers.remove(usersInBlock[index]);
                                },
                              );
                            });
                      }
                      return Center(child: Text('Loading users in your block'));
                    }),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: RaisedButton(
                      child: Text('Queue jointly'),
                      onPressed: () {
                        if (selectedUsers.isEmpty) {
                          showToast('Select users to queue with');
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QueuePage(
                                    isWashing: widget.isWashing,
                                    isDrying: widget.isDrying,
                                    washerQueueInstance: widget.washerQueueInstance,
                                    usersQueuingWith: selectedUsers,
                                ),
                                settings: RouteSettings(arguments: user)),
                          );
                        }
                      },
                    ))
              ]),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/storage.dart';

class ListItem extends StatefulWidget {
  final QueueInstance queue;
  final bool isMe;
  final bool isUs;
  final bool selectUserMode;
  final User user;
  final Function onUserSelected;
  final Function onUserUnSelected;
  final List<String> usersQueuedWith;

  ListItem(
      {this.queue,
      this.onUserSelected,
      this.onUserUnSelected,
      this.isMe, this.isUs,
      this.user,
      this.usersQueuedWith,
      this.selectUserMode = false});

  @override
  State<StatefulWidget> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  bool userSelected = false;
  bool selectUserMode;
  User user;
  bool isMe;
  bool isUs;
  bool showUsersQueuedWith;
  QueueInstance queue;
  List<String> usersQueuedWith;

  Future<List<User>> _getUsersQueuedWith() async {
    List<User> users = List<User>();
    for (String uid in usersQueuedWith) {
      User user = await DatabaseService(uid: uid).getUser();
      users.add(user);
    }

    return users;
  }

  FutureBuilder _getImage(User user) {
    return FutureBuilder(
      future: StorageService(user: user).getImageURL(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            margin: EdgeInsets.only(left: 8),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: NetworkImage(snapshot.data),
              ),
            ),
          );
        }

        return Container(
          padding: EdgeInsets.only(left: 8),
          width: 20,
          height: 20,
          child: CircleAvatar(
            backgroundColor: Colors.blueGrey[300],
          ),
        );
      },
    );
  }

  Widget _usersQueuedWith() {
    List<User> usersQueuedWith =
        widget.usersQueuedWith.map((uid) => User(uid: uid)).toList();

    return ListTile(
      leading: marker('With'),
      title: Center(
        child: Row(
          children: usersQueuedWith.map((user) {
            return _getImage(user);
          }).toList(),
        ),
      ),
    );
  }

  @override
  void initState() {
    selectUserMode = widget.selectUserMode;
    user = widget.user;
    queue = widget.queue;
    isMe = widget.isMe;
    isUs = widget.isUs;
    usersQueuedWith = widget.usersQueuedWith;
    showUsersQueuedWith = selectUserMode ? false : usersQueuedWith.isNotEmpty;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: InkWell(
        splashColor: Colors.blue[300],
        onTap: () {},
        child: Column(children: <Widget>[
          ListTile(
            leading: FutureBuilder(
              future: StorageService(user: selectUserMode ? user : queue.user)
                  .getImageURL(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        fit: BoxFit.fill,
                        image: NetworkImage(snapshot.data),
                      ),
                    ),
                  );
                }

                return CircleAvatar(
                  backgroundColor: Colors.blueGrey[300],
                );
              },
            ),
            title: Text(selectUserMode ? user.name : queue.user.name),
            subtitle: selectUserMode
                ? Text('Block ${user.block}/${user.room}')
                : Text(
                    '${queue.displayableTime['startTime']} - ${queue.displayableTime['endTime']}'),
            //Later, display only the end time
            trailing: selectUserMode
                ? Checkbox(
                    value: userSelected,
                    onChanged: (val) {
                      setState(() => userSelected = !userSelected);
                      if (userSelected) {
                        widget.onUserSelected();
                      } else {
                        widget.onUserUnSelected();
                      }
                    },
                  )
                : Container(
              width: 72,
                  child: Row(
                    children: <Widget> [
                      Visibility(
                        visible: isUs,
                        child: marker('Us'),
                      ),
                      Visibility(
                        visible: isMe,
                        child: marker('Me'),
                      )
                  ]),
                ),
          ),
          showUsersQueuedWith ? _usersQueuedWith() : Container()
        ]),
      ),
    );
  }
}

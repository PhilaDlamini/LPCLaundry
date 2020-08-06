import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/services/storage.dart';

class UserItem extends StatefulWidget {
  final User user;
  final Function onUserSelected;
  final Function onUserUnSelected;

  UserItem({
    this.onUserSelected,
    this.onUserUnSelected,
    this.user,
  });

  @override
  State<StatefulWidget> createState() => _UserItemState();
}

class _UserItemState extends State<UserItem> {
  bool userSelected = false;
  User user;

  @override
  void initState() {
    user = widget.user;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        splashColor: Colors.yellow,
        onTap: () {
          setState(() => userSelected = !userSelected);
          if (userSelected) {
            widget.onUserSelected();
          } else {
            widget.onUserUnSelected();
          }
        },
        child: ListTile(
          contentPadding: EdgeInsets.all(0),
          leading: FutureBuilder(
            future: StorageService(user: user).getImageURL(),
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
                backgroundColor: Colors.yellow,
              );
            },
          ),
          title: Text(user.name),
          subtitle: Text('Block ${user.block}/${user.room}'),
          trailing: Checkbox(
            value: userSelected,
            onChanged: (val) {
              setState(() => userSelected = !userSelected);
              if (userSelected) {
                widget.onUserSelected();
              } else {
                widget.onUserUnSelected();
              }
            },
          ),
        ),
      ),
    );
  }
}

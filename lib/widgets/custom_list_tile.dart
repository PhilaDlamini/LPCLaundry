import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/services/shared_preferences.dart';
import 'package:laundryqueue/services/storage.dart';

class CustomListTile extends StatelessWidget {
  final QueueInstance queueInstance;
  final List<QueueData> queueDataList;
  final List<String> usersQueuedWith;
  final String machineNumber;
  final String whichQueue;
  final bool queuedUnderOtherUser;
  final bool isUs;
  final bool isMe;

  CustomListTile(
      {this.queueInstance,
      this.queuedUnderOtherUser,
      this.usersQueuedWith,
      this.isMe,
      this.isUs,
      this.whichQueue,
      this.machineNumber,
      this.queueDataList});

  FutureBuilder _getImage(User user) {
    return FutureBuilder(
      future: StorageService(user: user).getImageURL(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
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
          width: 20,
          height: 20,
          child: CircleAvatar(
            backgroundColor: Colors.yellow,
          ),
        );
      },
    );
  }

  Widget _usersQueuedWith() {
    List<User> queuedWith =
        usersQueuedWith.map((uid) => User(uid: uid)).toList();

    //Create a list and add all the widget here
    List<Widget> widgetList = List<Widget>();
    widgetList.add(
      Container(
        margin: EdgeInsets.only(left: 64),
        child: marker('With'),
      ),
    );
    widgetList.addAll(queuedWith.map((user) {
      return Container(
          padding: EdgeInsets.only(left: 4), child: _getImage(user));
    }).toList());

    if (isUs && queuedUnderOtherUser) {
      widgetList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('('),
        ),
      );
      widgetList.add(marker('Me'));
      widgetList.add(Text(')'));
    }
    return Row(
      children: widgetList,
    );
  }

  Widget _getTrailingWidget(BuildContext context) {
    if (isUs && isMe && !queuedUnderOtherUser) {
      return Container(
        child: Row(
          children: <Widget>[
            marker('Us'),
            marker('Me'),
            IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(
                Icons.delete,
                color: Colors.grey,
              ),
              onPressed: () async {
                showUnQueueConfirmationDialog(context, onConfirmed: () async {
                  //Notify isolates of removal
                  await _notifyIsolateOfRemoval();

                  //Remove the alert dialog
                  Navigator.pop(context);

                  //Un-queue this user
                  await DatabaseService(
                          whichQueue: whichQueue,
                          location: 'Block ${queueInstance.user.block}',
                          machineNumber: machineNumber)
                      .unQueueUser(
                          queue: queueInstance, queueDataList: queueDataList);
                });
              },
            )
          ],
        ),
      );
    } else if (isUs && queuedUnderOtherUser) {
      return marker('Us');
    } else if (isMe && !queuedUnderOtherUser) {
      return Row(
        children: <Widget>[
          marker('Me'),
          IconButton(
            padding: EdgeInsets.all(0),
            icon: Icon(
              Icons.delete,
              color: Colors.grey,
            ),
            onPressed: () async {
              showUnQueueConfirmationDialog(context, onConfirmed: () async {
                //Notify isolates of removal
                await _notifyIsolateOfRemoval();

                //Remove the alert dialog
                Navigator.pop(context);

                //Un-queue this user
                await DatabaseService(
                        whichQueue: whichQueue,
                        location: 'Block ${queueInstance.user.block}',
                        machineNumber: machineNumber)
                    .unQueueUser(
                        queue: queueInstance, queueDataList: queueDataList);
              });
            },
          )
        ],
      );
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.yellow,
      child: Container(
        padding: EdgeInsets.only(top: 16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                FutureBuilder(
                  future: StorageService(user: queueInstance.user).getImageURL(),
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
                Container(
                  width: 100,
                  padding: EdgeInsets.only(left: 16),
                  child: Column(
                    children: <Widget>[
                      Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            queueInstance.user.name,
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          )),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                              '${queueInstance.displayableTime['startTime']} - ${queueInstance.displayableTime['endTime']}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                        ),
                      )
                    ],
                  ),
                ),
                Spacer(),
                _getTrailingWidget(context)
              ],
            ),
            usersQueuedWith.length != 0 ? _usersQueuedWith() : Container()
          ],
        ),
      ),
    );
  }

  Future _notifyIsolateOfRemoval() async {
    if (whichQueue == 'washer queue') {
      await Preferences.updateBoolData(
          Preferences.WASHER_QUEUE_REMOVED_AT_TIME, true);
    } else {
      await Preferences.updateBoolData(
          Preferences.DRIER_QUEUE_REMOVED_AT_TIME, true);
    }
  }
}

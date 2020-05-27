import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/models/QueueInstance.dart';

class ListItem extends StatelessWidget{

  final QueueInstance queue;
  final bool me;

  ListItem({this.queue, this.me});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: InkWell(
        splashColor: Colors.blue[300],
        onTap: () {

        },
        child: ListTile(
          leading: CircleAvatar( //Should replace with the actual image later : NetworkImage('url')
           backgroundColor: Colors.blueGrey[300],
          ),
          title: Text(queue.user.name),
          subtitle: Text('${queue.displayableTime['startTime']} - ${queue.displayableTime['endTime']}'), //Later, display only the end time
          trailing: Offstage(
            offstage: !me,
            child: Text('Me'),
          ),
        )
      )
    );
  }

}
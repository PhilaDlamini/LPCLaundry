import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/models/QueueInstance.dart';
import 'package:laundryqueue/services/shared_preferences.dart';

class QueueSummary extends StatelessWidget{
  final String title;
  final QueueInstance queueInstance;
  final Function toggle;

  QueueSummary({this.title, this.queueInstance, this.toggle});

  String getDate(QueueInstance queueInstance, String whichTime) {
    int timeInMillis = whichTime == 'startTime' ? queueInstance.startTimeInMillis : queueInstance.endTimeInMillis;
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeInMillis);
    int dayDifference = DateTime.now().day - dateTime.day;

    String date;
    String time = queueInstance.displayableTime[whichTime];

    if (dayDifference == 0) {
      date = 'today';
    } else if (dayDifference == 1) {
      date = 'yesterday';
    } else {
      date = '${dateTime.day}/${dateTime.month}';
    }
    return '$date, $time';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      margin: EdgeInsets.only(top: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16))
        ),
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),),
              subtitle: Text('Machine #${queueInstance.which}', style: TextStyle(fontSize: 16),),
              trailing: GestureDetector(
                child: Icon(Icons.delete),
                onTap: () async {
                  await Preferences.updateStringData(title == 'Washer' ? Preferences.LAST_WASHER_USED_DATA :
                  Preferences.LAST_DRIER_USED_DATA, null);
                  toggle();
                },
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: EdgeInsets.only(left: 16),
                height: 2,
                width: 50,
                color: Colors.yellow
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.done_all, color: Colors.greenAccent,),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('Finished ${getDate(queueInstance, 'endTime')}', style: TextStyle(fontSize: 14),),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.queue),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text('Started ${getDate(queueInstance, 'startTime')}', style: TextStyle(fontSize: 14),),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        )
      ),
    );
  }

}
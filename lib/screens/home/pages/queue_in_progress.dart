import 'package:flutter/material.dart';
import 'package:laundryqueue/models/Queue.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/streams/count_down.dart';
import 'package:laundryqueue/streams/queue_progress_stream.dart';

class QueueInProgress extends StatefulWidget{

  final Queue queue;
  final String title;
  final String whichQueue;
  final String machineNumber;
  QueueInProgress({this.queue, this.title, this.machineNumber, this.whichQueue});

  @override
  State<StatefulWidget> createState() => _QueueInProgressState();

}

class _QueueInProgressState extends State<QueueInProgress> {
  @override
  Widget build(BuildContext context) {

    return StreamBuilder(
       stream: CountDown(duration: widget.queue.timeLeftTillQueueEnd).stream,
       builder: (context, snapshot) {

         if(snapshot.hasData) {

           //If the time is zero sec, un-queue this user
           if(snapshot.data.trim() == '0s') {
             DatabaseService().finishQueue(
                 queue: widget.queue,
                 whichQueue: widget.whichQueue,
                 location: 'Block ${widget.queue.user.block}',
                 machineNumber: widget.machineNumber
             ).then((onValue) => 'Done!');
           }

           return Scaffold(
               appBar: AppBar(
                 elevation: 0,
                 backgroundColor: Colors.white,
                 title: Text(widget.title,
                 style: TextStyle(
                   color: Colors.black,
                   fontWeight: FontWeight.normal
                 ),
                 ),
                 actions: <Widget>[
                   Icon(Icons.more_vert, color: Colors.black,)
                 ],
               ),
             body: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: <Widget>[
                   StreamBuilder(
                     stream: QueueProgressStream(userQueue: widget.queue, type: 'till queueEnd').stream,
                     builder: (context, snapshot) {
                       if (snapshot.hasData) {
                         return Container(
                           width: 150,
                           height: 150,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: Colors.brown[200]
                           ),
                           child: CircularProgressIndicator(
                             value: snapshot.data,
                             strokeWidth: 2,
                           ),
                         );

                       }

                       return Container();
                     }
                   ),
                   Padding(
                     padding: const EdgeInsets.only(top: 16.0),
                     child: Text('Done @${widget.queue.displayableTime['endTime']}',
                       style: TextStyle(fontSize: 25),
                     ),
                   ),
                   Padding(
                     padding: const EdgeInsets.only(top: 16.0),
                     child: Text('${snapshot.data}',
                         style: TextStyle(fontSize: 25),
                     ),
                   ),
                   SizedBox(height:128,) //Just to push everything up a little bit
                 ],
               ),
             ),
           );
         }

         return Container();
       }
   );
  }

}
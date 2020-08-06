import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/widgets/machine_state.dart';

class MachineItem extends StatefulWidget {
  final String machineName;
  final String machineType;
  final User user;
  final bool isChecked;
  final Function onChanged;

  MachineItem(
      {this.machineName,
      this.onChanged,
      this.isChecked,
      this.user,
      this.machineType});

  @override
  State<StatefulWidget> createState() => _MachineItem();
}

class _MachineItem extends State<MachineItem> {
  bool isRunning;

  @override
  void initState() {
    isRunning = widget.isChecked;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
          isThreeLine: true,
          contentPadding: EdgeInsets.all(0),
          leading: MachineState(isRunning: isRunning),
          subtitle: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '${widget.machineType} in block ${widget.user.block}',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                ),
              ),
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(isRunning ? 'Running' : 'Disabled')),
            ],
          ),
          //Update!!
          title: Text(widget.machineName,
              style: TextStyle(fontWeight: FontWeight.w600)),
          trailing: GestureDetector(
            child: isRunning
                ? Icon(
                    Icons.block,
                    color: Colors.blueGrey,
                  )
                : Icon(
                    Icons.refresh,
                    color: Colors.blueGrey,
                  ),
            onTap: () {

              //If isRunning is true, then the user wants to disable this machine. Else, they want to enable it
              if(isRunning) {
                showDisableMachineDialog(
                  context,
                  onPositiveTap: () {
                    Navigator.pop(context);
                    isRunning = !isRunning;
                    widget.onChanged(isRunning);
                    setState(() {});
                  }
                );
              } else {
                showEnableMachineDialog(
                    context,
                    onPositiveTap: () {
                      Navigator.pop(context);
                      isRunning = !isRunning;
                      widget.onChanged(isRunning);
                      setState(() {});
                    }
                );
              }


            },
          ),
      ),
    );
  }
}

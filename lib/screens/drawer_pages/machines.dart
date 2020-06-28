import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/models/User.dart';
import 'package:laundryqueue/services/database.dart';
import 'package:laundryqueue/widgets/machine_item.dart';
import 'package:laundryqueue/widgets/placeholder_list_item.dart';

class Machines extends StatefulWidget {
  final User user;

  Machines({this.user});

  @override
  State<StatefulWidget> createState() => _MachinesState();
}

class _MachinesState extends State<Machines> {
  Widget _machinesList({Map<String, bool> washers, Map<String, bool> driers}) {
    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Washers',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        Column(
          children: washers == null
              ? List.generate(
                  3,
                  (index) => PlaceHolderListItem(
                    trailing: Icon(
                      Icons.block,
                      color: Colors.blueGrey,
                    ),
                  ),
                )
              : washers.keys.map((key) {
                  return MachineItem(
                    isChecked: washers[key],
                    machineName: '#$key',
                    machineType: 'Washer',
                    user: widget.user,
                    onChanged: (isRunning) async {
                      //TODO: Write code so that users need to get approval before modifying

                      washers[key] = isRunning;
                      await DatabaseService(user: widget.user)
                          .updateMachineAvailability('washer queue',
                              {'machines': washers.values.toList()});
                    },
                    //But for now, directly update
                  );
                }).toList(),
        ),
        SizedBox(height: 16),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Driers',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        Column(
          children: driers == null
              ? List.generate(
                  2,
                  (index) => PlaceHolderListItem(
                    trailing: Icon(
                      Icons.block,
                      color: Colors.blueGrey,
                    ),
                  ),
                )
              : driers.keys.map((key) {
                  return MachineItem(
                    machineName: '#$key',
                    isChecked: driers[key],
                    machineType: 'Drier',
                    user: widget.user,
                    onChanged: (value) async {
                      //TODO: Write code so that users need to get approval before modifying
                      //TODO: Also, what if there are no driers now?

                      //But for now, directly update
                      driers[key] = value;
                      await DatabaseService(user: widget.user)
                          .updateMachineAvailability('drier queue',
                              {'machines': driers.values.toList()});
                    },
                  );
                }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text('Block ${widget.user.block} machines',
              style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          leading: GestureDetector(
            child: Icon(Icons.clear, color: Colors.black),
            onTap: () {
              Navigator.popUntil(context, ModalRoute.withName(Navigator.defaultRouteName));
            },
          ),
          actions: <Widget>[popupMenuButton(context, user: widget.user)],
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16),
            child: FutureBuilder(
                future: DatabaseService(user: widget.user)
                    .loadAvailableMachines(getEnabledOnly: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _machinesList();
                  }

                  Map<String, bool> washers = snapshot.data['washers'];
                  Map<String, bool> driers = snapshot.data['driers'];

                  return _machinesList(washers: washers, driers: driers);
                }),
          ),
        ));
  }
}

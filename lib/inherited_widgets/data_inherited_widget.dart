import 'package:flutter/cupertino.dart';
import 'package:laundryqueue/data_handlers/queue_data.dart';
import 'package:laundryqueue/models/User.dart';

class DataInheritedWidget extends InheritedWidget {

  final User user;
  final List<QueueData> queueDataList;

  DataInheritedWidget({@required child, this.user, this.queueDataList}) : super(child: child);

  @override
  bool updateShouldNotify(DataInheritedWidget oldWidget) => oldWidget.user != user || oldWidget.queueDataList != queueDataList;

  static DataInheritedWidget of(context) => context.dependOnInheritedWidgetOfExactType<DataInheritedWidget>();
}
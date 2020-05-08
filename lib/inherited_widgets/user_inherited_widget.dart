import 'package:flutter/cupertino.dart';
import 'package:laundryqueue/models/User.dart';

class UserInheritedWidget extends InheritedWidget {

  final User user;

  UserInheritedWidget({@required child, this.user}) : super(child: child);

  @override
  bool updateShouldNotify(UserInheritedWidget oldWidget) => oldWidget.user != user;

  static UserInheritedWidget of(context) => context.dependOnInheritedWidgetOfExactType<UserInheritedWidget>();
}
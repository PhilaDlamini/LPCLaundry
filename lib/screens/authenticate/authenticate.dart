import 'package:flutter/material.dart';
import 'package:laundryqueue/screens/authenticate/register.dart';
import 'package:laundryqueue/screens/authenticate/sign_in.dart';

class Authenticate extends StatefulWidget{
  final Function toggleWrapper;

  Authenticate({this.toggleWrapper});

  @override
  State<StatefulWidget> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool _showSignIn = true;

  void toggleAuthenticate() {
    setState(() => _showSignIn = !_showSignIn);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _showSignIn ? SignIn(toggle: toggleAuthenticate) : Register(toggleWrapper: widget.toggleWrapper, toggle: toggleAuthenticate),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:laundryqueue/screens/authenticate/register.dart';
import 'package:laundryqueue/screens/authenticate/sign_in.dart';

class Authenticate extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {

  bool _showSignIn = false;

  void toggleView() {
    setState(() => _showSignIn = !_showSignIn);
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _showSignIn ? SignIn(toggle: toggleView) : Register(toggle: toggleView),
    );
  }

}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/widgets/loading.dart';

class SignIn extends StatefulWidget {
  final Function toggle;

  SignIn({this.toggle});

  @override
  State<StatefulWidget> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return loading ? Loading() :Scaffold(
        backgroundColor: Colors.brown[100],
        body: Container(
            margin: EdgeInsets.symmetric(vertical: 16, horizontal: 50),
            child: Form(
              key: _formKey,
              child: Column(children: <Widget>[
                TextFormField(
                  onChanged: (val) => email = val.trim(),
                  validator: (text) =>
                      text.isEmpty ? "Please enter email" : null,
                  decoration: createAccountInputDecoration.copyWith(hintText: "Email"),
                ),
                SizedBox(
                  height: 16,
                ),
                TextFormField(
                  obscureText: true,
                  decoration:
                      createAccountInputDecoration.copyWith(hintText: "Password"),
                  onChanged: (val) => password = val.trim(),
                  validator: (value) =>
                      value.isEmpty ? "Please enter password" : null,
                ),
                SizedBox(height: 32),
                Row(children: <Widget>[
                  RaisedButton(
                    child: Text("Submit"),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        setState(() => loading = true);
                        dynamic result = await _auth.sigInWithEmailAndPassword(
                            email: email, password: password);

                        if (result is PlatformException) {
                          setState(() => loading = false);
                          Scaffold.of(context).showSnackBar(
                            SnackBar(
                              duration: Duration(seconds: 3),
                              content: Text("Error: ${result.message}"),
                            ),
                          );
                        } else if (result == null) {
                          setState(() => loading = false);
                          Scaffold.of(context).showSnackBar(
                            SnackBar(
                              duration: Duration(seconds: 3),
                              content: Text("Error sigining in!"),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  FlatButton(
                    child: Text("Sign up"),
                    onPressed: widget.toggle,
                  )
                ]),
                Container(
                    margin: EdgeInsets.only(
                      top: 16,
                    ),
                    height: 1,
                    color: Colors.blueGrey),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FlatButton(
                    child: Text("Sign in anonymously"),
                    onPressed: () async {
                      setState(() => loading = true);
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          duration: Duration(seconds: 3),
                          content: Text("Temporarily disabled :)"),
                        ),
                      );

                      dynamic result = await _auth.signInAnon();

                      if(result is PlatformException) {
                      setState(() => loading = false);
                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: ${result.message}"),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else if (result == null) {
                        setState(() => loading = false);
                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Couldn't sign in anonymously"),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ]),
            )));
  }
}

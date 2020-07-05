import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laundryqueue/services/auth.dart';
import 'package:laundryqueue/constants/constants.dart';
import 'package:laundryqueue/widgets/progress.dart';

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
  bool resettingPassword = false;

  void _logIn() async {
    if (_formKey.currentState.validate()) {
      setState(() => loading = true);
      dynamic result = await _auth.sigInWithEmailAndPassword(
          email: email, password: password);

      if (result is PlatformException) {
        setState(() => loading = false);
        Scaffold.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 3),
            content: Text('Error: ${result.message}'),
          ),
        );
      } else if (result == null) {
        setState(() => loading = false);
        Scaffold.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 3),
            content: Text('Error sigining in!'),
          ),
        );
      }
    }
  }

  Widget _buttons({bool row}) {
    Widget confirmButton = roundedButton(
      text: resettingPassword ? 'Submit' : 'Log in',
      onPressed: resettingPassword
          ? () async {
              if (_formKey.currentState.validate()) {
                dynamic result =
                    await AuthService().sendPasswordResetEmail(email);

                if (result is PlatformException) {
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      duration: Duration(seconds: 7),
                      content: Text(result.message),
                    ),
                  );
                } else if (result is String) {
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      duration: Duration(seconds: 7),
                      content: Text(result),
                    ),
                  );
                } else {
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      duration: Duration(seconds: 7),
                      content: Text(
                          'An email has been sent to $email. Click on the link to reset your password'),
                    ),
                  );
                }
              }
            }
          : _logIn,
    );

    Widget toggleButton = roundedButton(
      color: Colors.white,
      text: resettingPassword ? 'Cancel' : 'Sign up',
      onPressed: resettingPassword
          ? () {
              setState(() => resettingPassword = false);
            }
          : widget.toggle,
    );

    return row
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              toggleButton,
              SizedBox(width: 4),
              confirmButton,
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              toggleButton,
              SizedBox(height: 16),
              confirmButton,
            ],
          );
  }

  Widget _getInputFields() {
    return Column(
      children: <Widget>[
        textFormField(
          'Email',
          initialValue: email,
          onChanged: (val) => email = val.trim(),
          validator: (text) => text.isEmpty ? "Please enter email" : null,
        ),
        Visibility(
          visible: !resettingPassword,
          child: textFormField(
            'Password',
            obscureText: true,
            onChanged: (val) => password = val.trim(),
            validator: (value) =>
                value.isEmpty ? "Please enter password" : null,
          ),
        ),
        Visibility(
          visible: !resettingPassword,
          child: Container(
            width: 250,
            padding: EdgeInsets.only(top: 16),
            child: GestureDetector(
              onTap: () {
                setState(() => resettingPassword = true);
              },
              child: Text(
                'Forgot password?',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey[900],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _portraitWidget(double height) {
    return Center(
      child: Container(
        height: height / 1.8,
        margin: EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            //  Icon(Icons.album, size: 32,),
            authTitle(resettingPassword
                ? 'Reset your password'
                : 'Log in to Laundry'),
            _getInputFields(),
            SizedBox(height: 32),
            _buttons(row: true),
          ],
        ),
      ),
    );
  }

  Widget _landscapeWidget(double height, double width) {
    double widgetWidth = width - 150;
    return resettingPassword
        ? Container(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: authTitle('Reset your password'),
                ),
                _getInputFields(),
                SizedBox(height: 24),
                _buttons(row: true),
              ],
            ),
          )
        : Center(
            child: Container(
              width: widgetWidth,
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Column(children: <Widget>[
                      //  Icon(Icons.album, size: 32,),
                      Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: authTitle('Log in to Laundry'),
                      ),
                      _getInputFields(),
                    ]),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(child: _buttons(row: false)),
                  ),
                ],
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    bool isPortrait = mediaQueryData.orientation == Orientation.portrait;
    double height = mediaQueryData.size.height;
    double width = mediaQueryData.size.width;

    return loading
        ? Progress(message: 'Logging in')
        : Scaffold(
            backgroundColor: Colors.yellow,
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Container(
                  height: height - 16,
                  color: Colors.white,
                  child: isPortrait
                      ? _portraitWidget(height)
                      : _landscapeWidget(height, width),
                ),
              ),
            ),
          );
  }
}

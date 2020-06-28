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

  void _logIn() async {
      if (_formKey.currentState.validate()) {
        setState(() => loading = true);
        dynamic result =
        await _auth.sigInWithEmailAndPassword(
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
    }

  Widget _getInputFields() {
    return Column(
      children: <Widget>[
        textFormField(
          'Email',
          onChanged: (val) => email = val.trim(),
          validator: (text) =>
          text.isEmpty ? "Please enter email" : null,
        ),
        textFormField(
          'Password',
          obscureText: true,
          onChanged: (val) => password = val.trim(),
          validator: (value) =>
          value.isEmpty ? "Please enter password" : null,
        ),
      ],
    );
  }

  Widget _portraitWidget(double height) {
    return Container(
      height: height - 16,
      color: Colors.white,
      child: Center(
        child: Container(
            height: height / 1.8,
            margin: EdgeInsets.all(8),
            child: Column(children: <Widget>[
              //  Icon(Icons.album, size: 32,),
              authTitle('Log in to Laundry'),
             _getInputFields(),
              SizedBox(height: 32),
              Container(
                width: 175,
                child: Row(children: <Widget>[
                  roundedButton(
                    text: "Log in",
                    onTapped: _logIn,
                  ),
                  flatButton(
                    text: 'Sign up',
                    onPressed: widget.toggle,
                  )
                ]),
              ),
//                Padding( //TODO: Move this to the register screen (or not? I don't know)
//                  padding: const EdgeInsets.all(8.0),
//                  child: FlatButton(
//                    child: Text("Sign in anonymously"),
//                    onPressed: () async {
//                      setState(() => loading = true);
//                      Scaffold.of(context).showSnackBar(
//                        SnackBar(
//                          duration: Duration(seconds: 3),
//                          content: Text("Temporarily disabled :)"),
//                        ),
//                      );
//
//                      dynamic result = await _auth.signInAnon();
//
//                      if(result is PlatformException) {
//                      setState(() => loading = false);
//                        Scaffold.of(context).showSnackBar(
//                          SnackBar(
//                            content: Text("Error: ${result.message}"),
//                            duration: Duration(seconds: 3),
//                          ),
//                        );
//                      } else if (result == null) {
//                        setState(() => loading = false);
//                        Scaffold.of(context).showSnackBar(
//                          SnackBar(
//                            content: Text("Couldn't sign in anonymously"),
//                            duration: Duration(seconds: 3),
//                          ),
//                        );
//                      }
//                    },
//                  ),
//                ),
            ])),
      ),
    );
  }

  Widget _landscapeWidget(double height, double width) {
    double widgetWidth = width - 150;
    return Container(
      color: Colors.white,
      height: height - 16,
      padding: EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: widgetWidth,
          child: Row(children: <Widget>[
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
            Container(
              margin: EdgeInsets.only(left: 48, top: 32, bottom: 32),
              width: 1,
              color: Colors.grey[400],
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  width: 110,
                  height: 120,
                  margin: EdgeInsets.only(top: 48),
                  child: Column(
                      children: <Widget>[
                    roundedButton(
                      text: "Log in",
                      onTapped: _logIn,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: flatButton(
                        text: 'Sign up',
                        onPressed: widget.toggle,
                      ),
                    )
                  ]),
                ),
              ),
            ),
          ]),
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
            backgroundColor:Colors.yellow,
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child:  isPortrait ? _portraitWidget(height) : _landscapeWidget(height, width)),
            ),
            );
  }

}

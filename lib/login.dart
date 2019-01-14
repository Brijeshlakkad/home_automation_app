import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/auth.dart';
import 'package:home_automation/models/user.dart';
import 'login_screen_presenter.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen>
    implements LoginScreenContract, AuthStateListener {
  BuildContext _ctx;

  bool _isLoading = false;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _password, _email;
  bool _autoValidate = false;
  LoginScreenPresenter _presenter;

  LoginScreenState() {
    _presenter = new LoginScreenPresenter(this);
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
  }

  void _submit() async{
    final form = formKey.currentState;

    if (form.validate()) {
      setState(() => _isLoading = true);
      form.save();
      await _presenter.doLogin(_email, _password);
    }else {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  void _showSnackBar(String text) {
    scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  onAuthStateChanged(AuthState state) {
    if (state == AuthState.LOGGED_IN) Navigator.of(_ctx).pushNamed("/home");
  }

  @override
  Widget build(BuildContext context) {
    String validateEmail(String value) {
      Pattern pattern =
          r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
      RegExp regex = new RegExp(pattern);
      if (!regex.hasMatch(value))
        return 'Enter Valid Email';
      else
        return null;
    }
    _ctx = context;
    var loginBtn = new Container(
      padding: EdgeInsets.only(top: 16.0),
      width: 400.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(46.0)),
      ),
      child: new RaisedButton(
        onPressed: _submit,
        child: new Text("LOGIN"),
      ),
    );
    var loginForm = new Column(
      children: <Widget>[
        new Text(
          "Home Automation",
          textScaleFactor: 2.0,
        ),
        SizedBox(
          height: 21.0,
        ),
        new Form(
          autovalidate: _autoValidate,
          key: formKey,
          child: new Column(
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.all(8.0),
                child: new TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (val) => _email = val,
                  validator: validateEmail,
                  decoration: new InputDecoration(labelText: "Email"),
                ),
              ),
              new Padding(
                padding: const EdgeInsets.all(8.0),
                child: new TextFormField(
                  onSaved: (val) => _password = val,
                  decoration: new InputDecoration(labelText: "Password"),
                ),
              ),
            ],
          ),
        ),
        _isLoading ? new CircularProgressIndicator() : loginBtn
      ],
      crossAxisAlignment: CrossAxisAlignment.center,
    );

    return new Scaffold(
      appBar: null,
      key: scaffoldKey,
      body: new Container(
        child: new Center(
          child: new Container(
            child: loginForm,
            height: 300.0,
            width: 300.0,
          ),
        ),
      ),
    );
  }

  @override
  void onLoginError(String errorTxt) {
    print("x");
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  @override
  void onLoginSuccess(User user) async {
    _showSnackBar(user.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.saveUser(user);
    var authStateProvider = new AuthStateProvider();
    authStateProvider.notify(AuthState.LOGGED_IN);
  }
}

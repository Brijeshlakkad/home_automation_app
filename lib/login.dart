import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/auth.dart';
import 'package:home_automation/models/user_data.dart';
import 'login_screen_presenter.dart';
import 'dart:ui';
import 'package:home_automation/colors.dart';
import 'package:home_automation/internet_access.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/home.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen>
    implements LoginScreenContract, AuthStateListener {
  bool _obscureText = true;
  bool _isLoadingValue = false;
  bool _isLoading = true;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _password, _email;
  bool _autoValidate = false;
  LoginScreenPresenter _presenter;
  bool _showError = false;

  LoginScreenState() {
    _presenter = new LoginScreenPresenter(this);
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
  }
  @override
  void initState() {
    super.initState();
  }

  void _submit() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    if (await checkInternetAccess.check()) {
      final form = formKey.currentState;
      setState(() => _showError = false);
      if (form.validate()) {
        setState(() => _isLoadingValue = true);
        form.save();
        await _presenter.doLogin(_email, _password);
      } else {
        setState(() {
          _autoValidate = true;
        });
      }
    } else {
      _showSnackBar("Please check internet connection");
    }
  }

  void _showSnackBar(String text) {
    scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  onAuthStateChanged(AuthState state, User user) {
    if (state == AuthState.LOGGED_IN) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => HomeScreen(user: user)));
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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

    String validatePassword(String value) {
      if (value.isEmpty)
        return 'Please enter password';
      else
        return null;
    }

    void _toggle() {
      setState(() {
        _obscureText = !_obscureText;
      });
    }

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
    var loginForm = new ListView(
      children: <Widget>[
        new Center(
          child: Text(
            "Home Automation",
            textScaleFactor: 2.0,
          ),
        ),
        SizedBox(
          height: 41.0,
        ),
        new Form(
          autovalidate: _autoValidate,
          key: formKey,
          child: new Column(
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.all(8.0),
                child: new TextFormField(
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (val) => _email = val,
                  validator: validateEmail,
                  decoration: new InputDecoration(labelText: "Email"),
                ),
              ),
              new Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: new TextFormField(
                        onSaved: (val) => _password = val,
                        validator: validatePassword,
                        decoration: new InputDecoration(
                          labelText: "Password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              // Based on passwordVisible state choose the icon
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).primaryColorDark,
                            ),
                            onPressed: _toggle,
                          ),
                        ),
                        obscureText: _obscureText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 30.0, bottom: 10.0),
          child: _showError
              ? Container(
                  child: Text(
                    "Email id or Password is wrong",
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                )
              : Container(),
        ),
        Center(
          child: _isLoadingValue ? new ShowProgress() : loginBtn,
        ),
        Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: FlatButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/signup');
            },
            child: Text(
              'Register?',
              textScaleFactor: 1,
              style: TextStyle(
                color: kHAutoBlue50,
              ),
            ),
          ),
        )
      ],
    );

    return new Scaffold(
        appBar: null,
        key: scaffoldKey,
        body: new Center(
          child: Container(
            padding: EdgeInsets.all(30.0),
            child: _isLoading ? ShowProgress() : loginForm,
          ),
        ));
  }

  @override
  void onLoginError(String errorTxt) {
    _showSnackBar(errorTxt);
    setState(() {
      _isLoadingValue = false;
      _showError = true;
    });
  }

  @override
  void onLoginSuccess(User user) async {
    _showSnackBar(user.toString());
    setState(() => _isLoadingValue = false);
    var db = new DatabaseHelper();
    await db.saveUser(user);
    final form = formKey.currentState;
    form.reset();
    var authStateProvider = new AuthStateProvider();
    authStateProvider.notify(AuthState.LOGGED_IN, user);
  }
}

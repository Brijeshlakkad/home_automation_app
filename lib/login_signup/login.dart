import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/auth.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/login_signup/login_screen_presenter.dart';
import 'dart:ui';
import 'package:home_automation/colors.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/home.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/login_signup/signup.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen>
    implements LoginScreenContract, AuthStateListener {
  DatabaseHelper db = new DatabaseHelper();
  User user;
  bool _obscureText = true;
  bool _isLoadingValue = false;
  bool _isLoading = true;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _password, _email;
  bool _autoValidate = false;
  LoginScreenPresenter _presenter;
  bool _showError = false;
  ShowDialog _showDialog;
  FocusNode _emailNode = new FocusNode();
  FocusNode _passwordNode = new FocusNode();
  LoginScreenState() {
    _presenter = new LoginScreenPresenter(this);
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
    authStateProvider.initState();
  }
  @override
  void initState() {
    _showDialog = new ShowDialog();
    super.initState();
  }

  Function callbackUser(User userDetails) {
    setState(() {
      this.user = userDetails;
    });
    db.updateUser(user);
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
      this.callbackUser(user);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                    user: this.user,
                    callbackUser: this.callbackUser,
                  )));
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _fieldFocusChange(
      BuildContext context, FocusNode current, FocusNode next) {
    current.unfocus();
    FocusScope.of(context).requestFocus(next);
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
                  onSaved: (val) => _email = val,
                  validator: validateEmail,
                  focusNode: _emailNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (val) {
                    _fieldFocusChange(context, _emailNode, _passwordNode);
                  },
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
                        focusNode: _passwordNode,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (val) {
                          _passwordNode.unfocus();
                          _submit();
                        },
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
            onPressed: () async {
              Map result = await Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SignupScreen()));
              if (result != null && result['success']) {
                _showDialog.showDialogCustom(
                    context, result['message'], "You may login now");
              }
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

    return new WillPopScope(
      onWillPop: () => new Future<bool>.value(false),
      child: new Scaffold(
        appBar: null,
        key: scaffoldKey,
        body: new Center(
          child: Container(
            padding: EdgeInsets.all(30.0),
            child: _isLoading ? ShowProgress() : loginForm,
          ),
        ),
      ),
    );
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

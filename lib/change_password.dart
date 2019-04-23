import 'package:flutter/material.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:flutter/services.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:flutter/cupertino.dart';

class ChangePassword extends StatefulWidget {
  final User user;
  final Function callbackUser;
  ChangePassword({this.user, this.callbackUser});
  @override
  ChangePasswordState createState() {
    return ChangePasswordState(user, callbackUser);
  }
}

class ChangePasswordState extends State<ChangePassword>
    implements UserUpdateContract {
  bool _isLoading = false;
  bool _isLoadingValue = false;
  bool internetAccess = false;
  CheckPlatform _checkPlatform;

  User user;
  Function callbackUser;
  ShowDialog showDialog;
  ShowInternetStatus _showInternetStatus;

  bool _isError = false;
  String _showError;
  String _oldPassword, _newPassword, _newCPassword;
  FocusNode _oldPasswordFocus = new FocusNode();
  FocusNode _newPasswordFocus = new FocusNode();
  FocusNode _newCPasswordFocus = new FocusNode();
  UserUpdatePresenter _userUpdatePresenter;

  var scaffoldKey = new GlobalKey<ScaffoldState>();
  var formKey = new GlobalKey<FormState>();
  bool _autoValidate = false;

  Function callbackThis(User userDetails) {
    this.callbackUser(userDetails);
    setState(() {
      this.user = userDetails;
    });
  }

  ChangePasswordState(User user, Function callbackUser) {
    this.user = user;
    this.callbackUser = callbackUser;
  }

  @override
  initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _showInternetStatus = new ShowInternetStatus();
    _userUpdatePresenter = new UserUpdatePresenter(this);
    _checkPlatform = new CheckPlatform(context: context);
    getInternetAccessObject();
    showDialog = new ShowDialog();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccess = await checkInternetAccess.check();
    setState(() {
      this.internetAccess = internetAccess;
    });
  }

  @override
  void onUserUpdateError(String errorString) {
    setState(() {
      _isLoadingValue = false;
    });
    this.showDialog.showDialogCustom(context, "Error", errorString);
  }

  @override
  void onUserUpdateSuccess(User userDetails) {
    this.callbackThis(userDetails);
    setState(() {
      _isLoadingValue = false;
    });
    this.showDialog.showDialogCustom(context, "Success", "Password Changed");
  }

  void _fieldFocusChange(
      BuildContext context, FocusNode current, FocusNode next) {
    current.unfocus();
    FocusScope.of(context).requestFocus(next);
  }

  Future _changePassword() async {
    await getInternetAccessObject();
    if (internetAccess) {
      var form = formKey.currentState;
      if (form.validate()) {
        form.save();
        if (_newPassword == _newCPassword) {
          this._isError = false;
          setState(() {
            _isLoadingValue = true;
          });
          await _userUpdatePresenter.doChangePassword(
              this.user.email, _oldPassword, _newPassword);
          form.reset();
        } else {
          this._isError = true;
          this._showError = "New passwords do not match";
        }
      } else {
        _autoValidate = true;
      }
    } else {
      this.showDialog.showDialogCustom(context, "Internet Connection Problem",
          "Please check your internet connection",
          fontSize: 17.0, boxHeight: 58.0);
    }
  }

  String passwordValidator(String value) {
    Pattern pattern =
        r'^(((?=.*[a-z])(?=.*[A-Z]))|((?=.*[a-z])(?=.*[0-9]))|((?=.*[A-Z])(?=.*[0-9])))(?=.{6,})';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Enter valid password';
    else
      return null;
  }

  String oldPasswordValidator(String value) {
    if (value == "" || value == null) {
      return "Please enter old password";
    }
    return null;
  }

  Widget _showBody(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
      child: Card(
        elevation: 10.0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: kHAutoBlue300, width: 2.0),
          ),
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Form(
              key: formKey,
              autovalidate: _autoValidate,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 10.0,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Old Password",
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onSaved: (value) {
                      _oldPassword = value;
                    },
                    obscureText: true,
                    validator: oldPasswordValidator,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    focusNode: _oldPasswordFocus,
                    onFieldSubmitted: (value) {
                      _fieldFocusChange(
                          context, _oldPasswordFocus, _newPasswordFocus);
                    },
                  ),
                  SizedBox(
                    height: 21.0,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "New Password",
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onSaved: (value) {
                      _newPassword = value;
                    },
                    validator: passwordValidator,
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    focusNode: _newPasswordFocus,
                    onFieldSubmitted: (value) {
                      _fieldFocusChange(
                          context, _newPasswordFocus, _newCPasswordFocus);
                    },
                  ),
                  SizedBox(
                    height: 21.0,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Confirm New Password",
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onSaved: (value) {
                      _newCPassword = value;
                    },
                    validator: passwordValidator,
                    obscureText: true,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    focusNode: _newCPasswordFocus,
                    onFieldSubmitted: (value) async {
                      await _changePassword();
                    },
                  ),
                  _isError
                      ? Container(
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                height: 10.0,
                              ),
                              Container(
                                child: Text(
                                  "$_showError",
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      : Container(),
                  SizedBox(
                    height: 21.0,
                  ),
                  _isLoadingValue
                      ? ShowProgress()
                      : RaisedButton(
                          color: kHAutoBlue300,
                          onPressed: () async {
                            await _changePassword();
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: new Text("Change Password"),
            )
          : new AppBar(
              title: new Text("Change Password"),
            ),
      body: internetAccess
          ? _isLoading ? ShowProgress() : _showBody(context)
          : _checkPlatform.isIOS()
              ? new CustomScrollView(
                  slivers: <Widget>[
                    new CupertinoSliverRefreshControl(
                      onRefresh: getInternetAccessObject,
                    ),
                    new SliverSafeArea(
                        top: false,
                        sliver: _showInternetStatus
                            .showInternetStatus(_checkPlatform.isIOS())),
                  ],
                )
              : RefreshIndicator(
                  child: _showInternetStatus
                      .showInternetStatus(_checkPlatform.isIOS()),
                  onRefresh: getInternetAccessObject,
                ),
    );
  }
}

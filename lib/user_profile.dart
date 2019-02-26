import 'package:flutter/material.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:flutter/services.dart';

class UserProfile extends StatefulWidget {
  final scaffoldKey;
  final User user;
  final Function callbackUser;
  UserProfile({this.scaffoldKey, this.user, this.callbackUser});
  @override
  UserProfileState createState() {
    return UserProfileState(scaffoldKey, user, callbackUser);
  }
}

class UserProfileState extends State<UserProfile>
    implements UserUpdateContract {
  var scaffoldKey;
  User user;
  ShowDialog showDialog;
  UserUpdatePresenter _userUpdatePresenter;
  var formKey = new GlobalKey<FormState>();
  String _name, _email, _mobile, _city;
  bool _autoValidate = false;
  bool _isLoading = false;
  bool internetAccess = false;
  Function callbackUser;

  Function callbackThis(User userDetails) {
    this.callbackUser(userDetails);
    setState(() {
      this.user = userDetails;
    });
  }

  UserProfileState(var scaffoldKey, User user, callbackUser) {
    this.scaffoldKey = scaffoldKey;
    this.user = user;
    this.callbackUser = callbackUser;
    setUserVariables();
  }

  @override
  initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _userUpdatePresenter = new UserUpdatePresenter(this);
    getInternetAccessObject();
    showDialog = new ShowDialog();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  setUserVariables() {
    _email = this.user.email;
    _name = this.user.name;
    _mobile = this.user.mobile;
    _city = this.user.city;
  }

  void _showSnackBar(String text) {
    this
        .scaffoldKey
        .currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void onUserUpdateError(String errorString) {
    setState(() {
      _isLoading = false;
    });
    _showSnackBar(errorString);
  }

  @override
  void onUserUpdateSuccess(User userDetails) {
    this.widget.callbackUser(userDetails);
    setState(() {
      _isLoading = false;
      this.user = userDetails;
      this
          .showDialog
          .showDialogCustom(context, "Success", "Profile Details Updated");
    });
  }

  Widget _showBody(BuildContext context) {
    String cityValidator(String value) {
      Pattern pattern = r'^[a-zA-Z]+$';
      RegExp regex = new RegExp(pattern);
      if (value.isEmpty)
        return 'City should not be empty';
      else if (!regex.hasMatch(value))
        return 'City should not contain special characters';
      else if (value.length <= 2)
        return "City should have more than 2 characters";
      else
        return null;
    }

    String contactValidator(String value) {
      Pattern pattern = r'^[0-9]{10}$';
      RegExp regex = new RegExp(pattern);
      if (value.isEmpty)
        return 'Contact should not be empty';
      else if (!regex.hasMatch(value))
        return 'Contact should only 10 contain numbers';
      else
        return null;
    }

    String nameValidator(String value) {
      Pattern pattern = r'^[a-zA-Z0-9]+$';
      Pattern pattern2 = r'^([0-9])+[a-zA-Z0-9]+$';
      RegExp regex = new RegExp(pattern);
      RegExp regex2 = new RegExp(pattern2);
      if (value.isEmpty)
        return 'Name should not be empty';
      else if (!regex.hasMatch(value))
        return 'Name should not contain special character';
      else if (regex2.hasMatch(value))
        return 'Name should not start with alpanumerics';
      else if (value.length <= 3)
        return "Name should have more than 3 characters";
      else
        return null;
    }

    return Container(
      padding: EdgeInsets.all(20.0),
      child: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Text(
                  "Edit Profile Details",
                  style: Theme.of(context)
                      .textTheme
                      .title
                      .copyWith(fontSize: 20.0),
                ),
                SizedBox(
                  height: 9.0,
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: kHAutoBlue300, width: 1.0)),
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    child: Form(
                      key: formKey,
                      autovalidate: _autoValidate,
                      child: Column(
                        children: <Widget>[
                          FlatButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _showSnackBar("Email can not be change!");
                            },
                            child: TextFormField(
                              initialValue: _email,
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: "Email",
                              ),
                            ),
                          ),
                          TextFormField(
                            initialValue: _name,
                            onSaved: (val) {
                              _name = val;
                            },
                            decoration: InputDecoration(
                              labelText: "Name",
                            ),
                            validator: nameValidator,
                          ),
                          TextFormField(
                            initialValue: _city,
                            onSaved: (val) {
                              _city = val;
                            },
                            decoration: InputDecoration(
                              labelText: "City",
                            ),
                            validator: cityValidator,
                          ),
                          TextFormField(
                            initialValue: _mobile,
                            onSaved: (val) {
                              _mobile = val;
                            },
                            decoration: InputDecoration(
                              labelText: "Mobile",
                            ),
                            validator: contactValidator,
                          ),
                          SizedBox(
                            height: 5.0,
                          ),
                          FlatButton(
                            color: kHAutoBlue300,
                            onPressed: () async {
                              await getInternetAccessObject();
                              if (internetAccess) {
                                var form = formKey.currentState;
                                if (form.validate()) {
                                  form.save();
                                  if (this.user.name != _name ||
                                      this.user.city != _city ||
                                      this.user.mobile != _mobile) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    await _userUpdatePresenter.doUpdateUser(
                                        _email, _name, _city, _mobile);
                                  } else {
                                    this.showDialog.showDialogCustom(context,
                                        "Success", "Profile Details Updated");
                                  }
                                } else {
                                  _autoValidate = true;
                                }
                              } else {
                                this.showDialog.showDialogCustom(
                                    context,
                                    "Internet Connection Problem",
                                    "Please check your internet connection",
                                    fontSize: 17.0,
                                    boxHeight: 58.0);
                              }
                            },
                            child: Text("Update"),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
//                Container(
//                  child: RaisedButton(
//                    onPressed: () {
//
//                    },
//                    child: Text("FAQs"),
//                  ),
//                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Learn N Earn"),
      ),
      body: _isLoading ? ShowProgress() : _showBody(context),
    );
  }
}

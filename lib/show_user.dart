import 'package:flutter/material.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/login_signup/logout.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';
import 'package:flutter/services.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/user_profile.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:home_automation/change_password.dart';
import 'package:home_automation/subscription.dart';
import 'package:home_automation/control_members.dart';

class ShowUser extends StatefulWidget {
  final User user;
  final Function callbackUser;
  ShowUser({this.user, this.callbackUser});
  @override
  ShowUserState createState() {
    return ShowUserState(user, callbackUser);
  }
}

class ShowUserState extends State<ShowUser> {
  bool internetAccess = false;
  CheckPlatform _checkPlatform;
  ShowDialog _showDialog;
  User user;
  Function callbackUser;
  ShowUserState(user, callbackUser) {
    this.user = user;
    this.callbackUser = callbackUser;
  }
  Function callbackThis(User user) {
    setState(() {
      this.user = user;
    });
    this.callbackUser(user);
  }

  @override
  initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _checkPlatform = new CheckPlatform(context: context);
    getInternetAccessObject();
    _showDialog = new ShowDialog();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Widget _showBody(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
      child: Column(
        children: <Widget>[
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfile(
                      user: this.user, callbackUser: this.callbackThis),
                ),
              );
            },
            title: Text("Edit Profile"),
          ),
          SizedBox(
            height: 5.0,
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePassword(
                      user: this.user, callbackUser: this.callbackThis),
                ),
              );
            },
            title: Text("Change Password"),
          ),
          SizedBox(
            height: 5.0,
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionScreen(user: this.user),
                ),
              );
            },
            title: Text("Subscription"),
          ),
          SizedBox(
            height: 5.0,
          ),
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ControlMember(
                        user: this.user,
                      ),
                ),
              );
            },
            title: Text("Control Members"),
          ),
          SizedBox(
            height: 5.0,
          ),
          ListTile(
            onTap: () {},
            title: Text("Share"),
          ),
          Container(
            padding: EdgeInsets.zero,
            child: GetLogOut(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: new Text("Home Automation"),
            )
          : new AppBar(
              title: new Text("Home Automation"),
            ),
      body: _showBody(context),
    );
  }
}

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
import 'package:home_automation/device/scheduled_devices.dart';
import 'package:share/share.dart';
import 'package:home_automation/utils/show_progress.dart';

class ShowUser extends StatefulWidget {
  final User user;
  final Function callbackUser;
  ShowUser({this.user, this.callbackUser});
  @override
  ShowUserState createState() {
    return ShowUserState(user, callbackUser);
  }
}

class ShowUserState extends State<ShowUser> implements UserUpdateContract {
  bool _isLoading = false;
  bool internetAccess = false;
  CheckPlatform _checkPlatform;
  ShowDialog _showDialog;

  User user;
  Function callbackUser;
  String link;

  UserUpdatePresenter _userUpdatePresenter;
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
    _showDialog = new ShowDialog();
    _checkPlatform = new CheckPlatform(context: context);
    _userUpdatePresenter = new UserUpdatePresenter(this);
    getInternetAccessObject();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getAppLink() async {
    await getInternetAccessObject();
    if (internetAccess) {
      setState(() {
        _isLoading = true;
      });
      String link =
          await _userUpdatePresenter.api.getAppLink(_checkPlatform.isIOS());
      setState(() {
        this.link = link;
      });
      setState(() {
        _isLoading = false;
      });
    } else {
      await _showDialog.showDialogCustom(context, "Internet Connection Problem",
          "Please check your internet connection",
          fontSize: 17.0, boxHeight: 58.0);
    }
  }

  @override
  void onUserUpdateSuccess(User user) {}
  @override
  void onUserUpdateError(String errorString) {
    _showDialog.showDialogCustom(context, "Error", errorString);
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduledDevice(
                        user: this.user,
                      ),
                ),
              );
            },
            title: Text("Scheduled Devices"),
          ),
          SizedBox(
            height: 5.0,
          ),
          ListTile(
            onTap: () async {
              try {
                await getAppLink();
                final RenderBox box = context.findRenderObject();
                Share.share(
                    "To install Home Automation, Click on below link \n $link",
                    sharePositionOrigin:
                        box.localToGlobal(Offset.zero) & box.size);
              } on Exception catch (error) {
                onUserUpdateError(error.toString());
              }
              if (_isLoading)
                setState(() {
                  _isLoading = false;
                });
            },
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
      body: _isLoading ? ShowProgress() : _showBody(context),
    );
  }
}

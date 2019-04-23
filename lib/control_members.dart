import 'package:flutter/material.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:home_automation/models/member_data.dart';

class ControlMember extends StatefulWidget {
  final User user;
  ControlMember({this.user});
  @override
  _ControlMemberState createState() => _ControlMemberState(user);
}

class _ControlMemberState extends State<ControlMember>
    implements MemberContract {
  bool _isLoading = true;
  bool internetAccess = false;
  CheckPlatform _checkPlatform;

  User user;
  ShowDialog showDialog;
  ShowInternetStatus _showInternetStatus;
  UserUpdatePresenter _userUpdatePresenter;

  var scaffoldKey = new GlobalKey<ScaffoldState>();
  var formKey = new GlobalKey<FormState>();
  bool _autoValidate = false;
  var subscriptionRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  String _memberEmail;
  String _hwSeries;
  List<Hw> hwList = new List<Hw>();
  FocusNode _memberFocus = new FocusNode();

  MemberPresenter _memberPresenter;
  List<Member> memberList = new List<Member>();

  _ControlMemberState(User user) {
    this.user = user;
  }

  @override
  initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    getMemberList();
    showDialog = new ShowDialog();
    _memberPresenter = new MemberPresenter(this);
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getMemberList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      memberList = await _memberPresenter.api.getMembers(this.user);
    }
    await getHardwareList();
    setState(() => _isLoading = false);
  }

  Future getHardwareList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      hwList = await _memberPresenter.api.getHardwareList(this.user);
      if (hwList.length > 0) {
        hwList.add(Hw("Permission for all hardwares", "-99"));
        _hwSeries = hwList[0].hwSeries;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void onError(String errorString) {
    setState(() {
      _isLoading = false;
    });
    this.showDialog.showDialogCustom(context, "Error", errorString);
  }

  @override
  void onSuccess(String responseMessage) async {
    await getMemberList();
    setState(() {
      _isLoading = false;
    });
    this.showDialog.showDialogCustom(context, "Success", responseMessage);
  }

  Widget _getMemberObject(List<Member> memberList, int index, int length) {
    return Card(
      elevation: 5.0,
      child: Dismissible(
        key: Key(memberList[index].email),
        onDismissed: (direction) {
          Member member = memberList[index];
          setState(() {
            this.memberList.removeAt(index);
          });
          _memberPresenter.doRemoveMember(this.user, member);
        },
        background: Container(
          color: Colors.red,
          child: Center(
            child: Text(
              "Remove",
              style: TextStyle(color: Colors.white, fontSize: 19.0),
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: kHAutoBlue300, width: 2.0),
          ),
          child: Container(
            margin: EdgeInsets.all(10.0),
            child: ListTile(
              leading: Text(
                "${memberList[index].name[0].toUpperCase()}",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 21.0,
                ),
              ),
              title: Text(
                "${memberList[index].email}",
                style: TextStyle(height: 1.2),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text("${memberList[index].name}"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      //Text('Hardware'),
                      Text(
                        "${memberList[index].hwName}",
                        style: TextStyle(letterSpacing: 1.0),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future _saveMember() async {
    final form = formKey.currentState;
    if (form.validate()) {
      setState(() => _isLoading = true);
      form.save();
      await _memberPresenter.doSaveMember(user, _memberEmail, _hwSeries);
    } else {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String emailValidator(String value) {
      Pattern pattern =
          r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
      RegExp regex = new RegExp(pattern);
      if (!regex.hasMatch(value))
        return 'Enter Valid email';
      else
        return null;
    }

    Widget getTitle() {
      return Center(
        child: Container(
          padding: EdgeInsets.only(top: 30.0, bottom: 10.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 1.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Text(
              "Members",
              style: TextStyle(
                color: Color.fromRGBO(100, 100, 100, 1.0),
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ),
      );
    }

    Widget memberForm() {
      return Container(
        padding: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
        child: Form(
          key: formKey,
          autovalidate: _autoValidate,
          child: Column(
            children: <Widget>[
              TextFormField(
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                focusNode: _memberFocus,
                onSaved: (val) {
                  _memberEmail = val;
                },
                onFieldSubmitted: (val) async {
                  await _saveMember();
                },
                validator: emailValidator,
                decoration: InputDecoration(
                  hintText: "Member Email ID:",
                  contentPadding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                  prefixIcon: Icon(
                    Icons.email,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
              ),
              SizedBox(
                height: 21.0,
              ),
              new InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select Hardware',
                  contentPadding: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 10.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                  prefixIcon: Icon(
                    Icons.toys,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: new DropdownButton<String>(
                    value: _hwSeries,
                    items: hwList.map((Hw hw) {
                      return new DropdownMenuItem<String>(
                        value: hw.hwSeries,
                        child: new Text("${hw.hwName}"),
                      );
                    }).toList(),
                    onChanged: (String val) {
                      setState(() {
                        _hwSeries = val;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 21.0,
              ),
              RaisedButton(
                color: kHAutoBlue300,
                onPressed: () async {
                  await _saveMember();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  margin: EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.fingerprint,
                      ),
                      Text(
                        " Save",
                        style: TextStyle(
                          fontSize: 15.0,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }

    Widget createListViewIOS(
        BuildContext context, List<Member> memberList, List<Hw> hwList) {
      var len = 0;
      if (memberList != null) {
        len = memberList.length;
      }
      return new SliverList(
        delegate: new SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (hwList.length == 0 && index == 0) {
              return Container(
                padding: EdgeInsets.only(top: 10.0),
              );
            } else if (hwList.length == 0 && index == 1) {
              return Container(
                child: Center(
                  child: Text("You do not have any hardware"),
                ),
              );
            }
            if (index == 0) {
              return memberForm();
            }
            if (len != 0) {
              if (index == 1) {
                return getTitle();
              }
              return _getMemberObject(memberList, index - 2, len);
            }
          },
          childCount: len + 2,
        ),
      );
    }

    Widget createListView(
        BuildContext context, List<Member> memberList, List<Hw> hwList) {
      var len = 0;
      if (memberList != null) {
        len = memberList.length;
      }
      return new ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          if (hwList.length == 0 && index == 0) {
            return Container(
              padding: EdgeInsets.only(top: 10.0),
            );
          } else if (hwList.length == 0 && index == 1) {
            return Container(
              child: Center(
                child: Text("You do not have any hardware"),
              ),
            );
          }
          if (index == 0) {
            return memberForm();
          }
          if (len != 0) {
            if (index == 1) {
              return getTitle();
            }
            return _getMemberObject(memberList, index - 2, len);
          }
        },
        itemCount: len + 2,
      );
    }

    return Scaffold(
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: new Text("Control Members"),
            )
          : AppBar(
              title: Text("Control Members"),
            ),
      body: _isLoading
          ? ShowProgress()
          : internetAccess
              ? _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getMemberList),
                        new SliverSafeArea(
                          top: false,
                          sliver:
                              createListViewIOS(context, memberList, hwList),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      key: subscriptionRefreshIndicatorKey,
                      child: createListView(context, memberList, hwList),
                      onRefresh: getMemberList,
                    )
              : _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getMemberList),
                        new SliverSafeArea(
                            top: false,
                            sliver: _showInternetStatus
                                .showInternetStatus(_checkPlatform.isIOS())),
                      ],
                    )
                  : RefreshIndicator(
                      key: subscriptionRefreshIndicatorKey,
                      child: _showInternetStatus
                          .showInternetStatus(_checkPlatform.isIOS()),
                      onRefresh: getMemberList,
                    ),
    );
  }
}

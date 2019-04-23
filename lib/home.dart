import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/room.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/delete_confirmation.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/get_to_user_profile.dart';
import 'package:home_automation/utils/custom_services.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  final Function callbackUser;
  HomeScreen({this.user, this.callbackUser});
  @override
  HomeScreenState createState() {
    return new HomeScreenState(user, callbackUser);
  }
}

class HomeScreenState extends State<HomeScreen> implements HomeScreenContract {
  bool _isLoading = true;
  bool internetAccess = false;
  ShowDialog _showDialog;
  CheckPlatform _checkPlatform;
  DeleteConfirmation _deleteConfirmation;
  ShowInternetStatus _showInternetStatus;
  GoToUserProfile _goToUserProfile;
  CustomService _customService;

  String _homeName;
  List<Home> homeList = new List<Home>();
  var homeNameFormKey = new GlobalKey<FormState>();
  var homeReNameFormKey = new GlobalKey<FormState>();
  bool _autoValidateHomeName = false;
  bool _autoValidateHomeReName = false;

  final scaffoldKey = new GlobalKey<ScaffoldState>();
  var homeRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  void _showSnackBar(String text) {
    scaffoldKey.currentState.removeCurrentSnackBar();
    scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  User user;
  Function callbackUser;

  Function callbackThis(User user) {
    this.callbackUser(user);
    setState(() {
      this.user = user;
    });
  }

  HomeScreenPresenter _presenter;
  HomeScreenState(User user, Function callbackUser) {
    this.user = user;
    this.callbackUser = callbackUser;
    _presenter = new HomeScreenPresenter(this);
  }

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _customService = new CustomService();
    _showDialog = new ShowDialog();
    _deleteConfirmation = new DeleteConfirmation();
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    getHomeList();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccess = await checkInternetAccess.check();
    setState(() {
      this.internetAccess = internetAccess;
    });
  }

  Future getHomeList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      List<Home> homeList = await _presenter.api.getAllHome();
      if (homeList != null) {
        this.homeList = homeList.toList();
      } else {
        this.homeList = new List<Home>();
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void onSuccess(Home home) async {
    _showDialog.showDialogCustom(context, "Success", "$home Home created");
    getHomeList();
  }

  void onSuccessDelete(Home home) async {
    _showDialog.showDialogCustom(context, "Success", "$home Home Deleted");
    getHomeList();
  }

  void onSuccessRename(Home home) async {
    getHomeList();
  }

  @override
  void onError(String errorTxt) {
    _showDialog.showDialogCustom(context, "Error", errorTxt);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    _goToUserProfile = new GoToUserProfile(
        context: context,
        isIOS: _checkPlatform.isIOS(),
        user: user,
        callbackThis: this.callbackThis);
    _createHome(String homeName) async {
      await _presenter.doCreateHome(homeName);
    }

    _renameHome(Home home, String homeName) async {
      await _presenter.doRenameHome(home, homeName);
    }

    List getListOfHomeName() {
      List<Home> list = homeList;
      if (list != null) {
        List homeNameList = new List();
        for (int i = 0; i < list.length; i++) {
          homeNameList.add(list[i].homeName.toLowerCase());
        }
        return homeNameList;
      }
      return null;
    }

    existHomeName(String homeName) {
      List list = getListOfHomeName();
      if (list == null) {
        return false;
      }
      for (int i = 0; i < list.length; i++) {
        if (homeName == list[i]) return true;
      }
      return false;
    }

    homeValidator(String val, String ignoreName) {
      RegExp homeNamePattern = new RegExp(r"^(([A-Za-z]+)([1-9]*))$");
      if (val.isEmpty) {
        return 'Please enter home name.';
      } else if (!homeNamePattern.hasMatch(val) ||
          val.length < 3 ||
          val.length > 8) {
        return "Home Name invalid.";
      } else if (existHomeName(val.toLowerCase()) && val != ignoreName) {
        return '"${_customService.ucFirst(val)}" Home already exists.';
      } else {
        return null;
      }
    }

    _showHomeNameDialog() async {
      _checkPlatform.isIOS()
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Create Home Here"),
                    content: CupertinoTextField(
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      onSubmitted: (val) async {
                        await getInternetAccessObject();
                        if (internetAccess) {
                          if (homeValidator(val, null) == null) {
                            Navigator.pop(context);
                            setState(() {
                              _isLoading = true;
                            });
                            _createHome(val);
                          } else {
                            Navigator.pop(context);
                            _showSnackBar("${homeValidator(val, null)}");
                          }
                        } else {
                          Navigator.pop(context);
                          this._showDialog.showDialogCustom(
                              context,
                              "Internet Connection Problem",
                              "Please check your internet connection",
                              fontSize: 17.0,
                              boxHeight: 58.0);
                        }
                      },
                    ),
                  ),
            )
          : await showDialog<String>(
              context: context,
              builder: (BuildContext context) => new AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    content: new Row(
                      children: <Widget>[
                        new Expanded(
                          child: Form(
                            autovalidate: _autoValidateHomeName,
                            key: homeNameFormKey,
                            child: new TextFormField(
                              onSaved: (val) => _homeName = val,
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (val) async {
                                await getInternetAccessObject();
                                if (internetAccess) {
                                  var form = homeNameFormKey.currentState;
                                  if (form.validate()) {
                                    form.save();
                                    Navigator.pop(context);
                                    setState(() {
                                      _isLoading = true;
                                      _autoValidateHomeName = false;
                                    });
                                    _createHome(_homeName);
                                  } else {
                                    setState(() {
                                      _autoValidateHomeName = true;
                                    });
                                  }
                                } else {
                                  Navigator.pop(context);
                                  this._showDialog.showDialogCustom(
                                      context,
                                      "Internet Connection Problem",
                                      "Please check your internet connection",
                                      fontSize: 17.0,
                                      boxHeight: 58.0);
                                }
                              },
                              validator: (val) => homeValidator(val, null),
                              decoration: new InputDecoration(
                                labelText: 'Home',
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    actions: <Widget>[
                      new FlatButton(
                          child: const Text('CANCEL'),
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                      new FlatButton(
                        child: const Text('CREATE'),
                        onPressed: () async {
                          await getInternetAccessObject();
                          if (internetAccess) {
                            var form = homeNameFormKey.currentState;
                            if (form.validate()) {
                              form.save();
                              Navigator.pop(context);
                              setState(() {
                                _isLoading = true;
                                _autoValidateHomeName = false;
                              });
                              _createHome(_homeName);
                            } else {
                              setState(() {
                                _autoValidateHomeName = true;
                              });
                            }
                          } else {
                            Navigator.pop(context);
                            this._showDialog.showDialogCustom(
                                context,
                                "Internet Connection Problem",
                                "Please check your internet connection",
                                fontSize: 17.0,
                                boxHeight: 58.0);
                          }
                        },
                      )
                    ],
                  ),
            );
    }

    _showHomeReNameDialog(Home home) async {
      _checkPlatform.isIOS()
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Modify Your Home Name Here"),
                    content: CupertinoTextField(
                      autofocus: true,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (val) async {
                        await getInternetAccessObject();
                        if (internetAccess) {
                          if (val != home.homeName) {
                            if (homeValidator(val, home.homeName) == null) {
                              Navigator.pop(context);
                              setState(() {
                                _isLoading = true;
                              });
                              _renameHome(home, val);
                            } else {
                              Navigator.pop(context);
                              _showSnackBar(
                                  "${homeValidator(val, home.homeName)}");
                            }
                          } else {
                            Navigator.pop(context);
                          }
                        } else {
                          Navigator.pop(context);
                          this._showDialog.showDialogCustom(
                              context,
                              "Internet Connection Problem",
                              "Please check your internet connection",
                              fontSize: 17.0,
                              boxHeight: 58.0);
                        }
                      },
                    ),
                  ),
            )
          : await showDialog<String>(
              context: context,
              builder: (BuildContext context) => new AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    content: new Row(
                      children: <Widget>[
                        new Expanded(
                          child: Form(
                            autovalidate: _autoValidateHomeReName,
                            key: homeReNameFormKey,
                            child: new TextFormField(
                              initialValue: home.homeName,
                              onSaved: (val) => _homeName = val,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (val) async {
                                await getInternetAccessObject();
                                if (internetAccess) {
                                  var form = homeReNameFormKey.currentState;
                                  if (form.validate()) {
                                    form.save();
                                    Navigator.pop(context);
                                    setState(() {
                                      _isLoading = true;
                                      _autoValidateHomeReName = false;
                                    });
                                    _renameHome(home, _homeName);
                                  } else {
                                    setState(() {
                                      _autoValidateHomeReName = true;
                                    });
                                  }
                                } else {
                                  Navigator.pop(context);
                                  this._showDialog.showDialogCustom(
                                      context,
                                      "Internet Connection Problem",
                                      "Please check your internet connection",
                                      fontSize: 17.0,
                                      boxHeight: 58.0);
                                }
                              },
                              autofocus: true,
                              validator: (val) => homeValidator(val, null),
                              decoration: new InputDecoration(
                                labelText: 'Home',
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    actions: <Widget>[
                      new FlatButton(
                        child: const Text('CANCEL'),
                        onPressed: () {
                          var form = homeReNameFormKey.currentState;
                          form.reset();
                          Navigator.pop(context);
                        },
                      ),
                      new FlatButton(
                        child: const Text('RENAME'),
                        onPressed: () async {
                          await getInternetAccessObject();
                          if (internetAccess) {
                            var form = homeReNameFormKey.currentState;
                            if (form.validate()) {
                              form.save();
                              Navigator.pop(context);
                              setState(() {
                                _isLoading = true;
                                _autoValidateHomeReName = false;
                              });
                              _renameHome(home, _homeName);
                            } else {
                              setState(() {
                                _autoValidateHomeReName = true;
                              });
                            }
                          } else {
                            Navigator.pop(context);
                            this._showDialog.showDialogCustom(
                                context,
                                "Internet Connection Problem",
                                "Please check your internet connection",
                                fontSize: 17.0,
                                boxHeight: 58.0);
                          }
                        },
                      ),
                    ],
                  ),
            );
    }

    // to show dialogue to ensure of deleting operation
    _deleteHome(Home home) async {
      await getInternetAccessObject();
      if (internetAccess) {
        bool status = await _deleteConfirmation.showConfirmDialog(
            context, _checkPlatform.isIOS());
        if (status) {
          setState(() {
            _isLoading = true;
          });
          await _presenter.doDeleteHome(home);
        }
      } else {
        this._showDialog.showDialogCustom(
            context,
            "Internet Connection Problem",
            "Please check your internet connection",
            fontSize: 17.0,
            boxHeight: 58.0);
      }
    }

    Widget _getHomeObject(List<Home> homeList, int index, int len) {
      if (index == len) {
        return Center(
          child: SizedBox(
            width: 130.0,
            height: 130.0,
            child: RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(30.0)),
              onPressed: () async {
                await _showHomeNameDialog();
              },
              color: kHAutoBlue300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.add),
                  Text('Add Home'),
                ],
              ),
            ),
          ),
        );
      }
      return Center(
        child: InkWell(
          onTap: () async {
            await getInternetAccessObject();
            if (internetAccess) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => RoomScreen(
                        user: user,
                        callbackUser: callbackThis,
                        home: homeList[index])),
              );
            } else {
              this._showDialog.showDialogCustom(
                  context,
                  "Internet Connection Problem",
                  "Please check your internet connection",
                  fontSize: 17.0,
                  boxHeight: 58.0);
            }
          },
          splashColor: kHAutoBlue300,
          child: Container(
            padding: EdgeInsets.only(
                left: 10.0, top: 20.0, bottom: 20.0, right: 10.0),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Hero(
                      tag: homeList[index].homeName,
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.0, top: 10.0),
                        child: Text(
                          '${homeList[index].homeName}',
                          textAlign: TextAlign.left,
                          style: Theme.of(context)
                              .textTheme
                              .headline
                              .copyWith(fontSize: 18.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40.0,
                  ),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 40.0,
                        child: FlatButton(
                          onPressed: () async {
                            await _showHomeReNameDialog(homeList[index]);
                          },
                          child: Icon(Icons.edit),
                        ),
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      SizedBox(
                        width: 40.0,
                        child: FlatButton(
                          onPressed: () async {
                            await _deleteHome(homeList[index]);
                          },
                          child: Icon(Icons.delete),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget createListView(BuildContext context, List<Home> homeList) {
      var len = 0;
      if (homeList != null) {
        len = homeList.length;
      }
      return new GridView.count(
        crossAxisCount: 2,
        children: List.generate(
          len + 1,
          (index) {
            return _getHomeObject(homeList, index, len);
          },
        ),
      );
    }

    Widget createListViewIOS(BuildContext context, List<Home> homeList) {
      var len = 0;
      if (homeList != null) {
        len = homeList.length;
      }
      return new SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 1.0,
          crossAxisCount: 2,
        ),
        delegate: new SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return _getHomeObject(homeList, index, len);
          },
          childCount: len + 1,
        ),
      );
    }

    Future<bool> _backButtonPressed() {
      return showDialog<bool>(
        context: context,
        builder: (BuildContext context) => new AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              title: new Container(
                child: Text('Are you sure, you want to log out?'),
              ),
              actions: <Widget>[
                new FlatButton(
                  child: const Text('NO'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                new FlatButton(
                  child: const Text('YES'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
      );
    }

    return WillPopScope(
      onWillPop: () => new Future<bool>.value(false),
      child: new Scaffold(
        key: scaffoldKey,
        appBar: _checkPlatform.isIOS()
            ? CupertinoNavigationBar(
                backgroundColor: kHAutoBlue100,
                leading: Container(),
                middle: new Text(
                  "Home Automation",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 15.0,
                  ),
                ),
                trailing: _goToUserProfile.showUser(),
              )
            : new AppBar(
                leading: Container(),
                title: new Text(
                  "Home Automation",
                  style: TextStyle(
                    fontSize: 15.0,
                  ),
                ),
                actions: <Widget>[
                  _goToUserProfile.showUser(),
                ],
              ),
        body: _isLoading
            ? ShowProgress()
            : internetAccess
                ? _checkPlatform.isIOS()
                    ? new CustomScrollView(
                        slivers: <Widget>[
                          new CupertinoSliverRefreshControl(
                              onRefresh: getHomeList),
                          new SliverSafeArea(
                            top: false,
                            sliver: createListViewIOS(context, homeList),
                          ),
                        ],
                      )
                    : RefreshIndicator(
                        key: homeRefreshIndicatorKey,
                        child: createListView(context, homeList),
                        onRefresh: getHomeList,
                      )
                : _checkPlatform.isIOS()
                    ? new CustomScrollView(
                        slivers: <Widget>[
                          new CupertinoSliverRefreshControl(
                              onRefresh: getHomeList),
                          new SliverSafeArea(
                              top: false,
                              sliver: _showInternetStatus
                                  .showInternetStatus(_checkPlatform.isIOS())),
                        ],
                      )
                    : RefreshIndicator(
                        key: homeRefreshIndicatorKey,
                        child: _showInternetStatus
                            .showInternetStatus(_checkPlatform.isIOS()),
                        onRefresh: getHomeList,
                      ),
      ),
    );
  }
}

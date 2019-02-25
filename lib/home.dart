import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/home_object.dart';
import 'package:home_automation/logout.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/internet_access.dart';
import 'package:home_automation/models/user_data.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  HomeScreen({this.user});
  @override
  HomeScreenState createState() {
    return new HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> implements HomeScreenContract {
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  var homeNameFormKey = new GlobalKey<FormState>();
  var homeReNameFormKey = new GlobalKey<FormState>();
  bool _isLoading = false;
  bool flag = false;
  bool _autoValidateHomeName = false;
  bool _autoValidateHomeReName = false;
  var homeRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  List<Home> homeList = new List<Home>();
  var db = new DatabaseHelper();
  String _homeName;
  bool internetAccess = false;
  void _showSnackBar(String text) {
    scaffoldKey.currentState.removeCurrentSnackBar();
    scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });
    getHomeList();
    super.initState();
  }

  HomeScreenPresenter _presenter;
  HomeScreenState() {
    _presenter = new HomeScreenPresenter(this);
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getHomeList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      homeRefreshIndicatorKey.currentState?.show();
      homeList = await _presenter.api.getAllHome();
      if (homeList != null) {
        setState(() {
          homeList = homeList.toList();
        });
        onSuccessGetAllHome(homeList);
      }
    } else {
      setState(() {
        homeList = new List<Home>();
        _isLoading = false;
      });
      _showSnackBar("Please check internet connection");
    }
  }

  @override
  void onSuccess(Home home) async {
    _showSnackBar("Created ${home.toString()} home");
    setState(() => _isLoading = false);
//    var db = new DatabaseHelper();
//    await db.saveHome(home);
  }

  @override
  void onSuccessGetAllHome(List<Home> homeList) async {
    if (homeList != null) {
      _showSnackBar("Got ${homeList.length}");
      setState(() => _isLoading = false);
//      var db = new DatabaseHelper();
//      await db.saveAllHome(homeList);
    }
  }

  void onSuccessDelete(Home home) async {
    _showSnackBar("Deleted ${home.homeName} home");
    setState(() => _isLoading = false);
//    var db = new DatabaseHelper();
//    await db.deleteHome(home);
    getHomeList();
  }

  void onSuccessRename(Home home) async {
    _showSnackBar(home.toString());
    setState(() => _isLoading = false);
//    var db = new DatabaseHelper();
//    await db.renameHome(home);
    getHomeList();
  }

  @override
  void onError(String errorTxt) {
    print("x");
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  bool _isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS ? true : false;
  }

  @override
  Widget build(BuildContext context) {
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
          homeNameList.add(list[i].homeName);
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
      if (val.isEmpty) {
        return 'Please enter home name';
      } else if (existHomeName(val) && val != ignoreName) {
        return 'Home already exists';
      } else {
        return null;
      }
    }

    _showHomeNameDialog() async {
      _isIOS(context)
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Create Home Here"),
                    content: CupertinoTextField(
                      autofocus: true,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      onSubmitted: (val) {
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
                          onPressed: () {
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
                          })
                    ],
                  ),
            );
    }

    _showHomeReNameDialog(Home home) async {
      _isIOS(context)
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Modify Your Home Name Here"),
                    content: CupertinoTextField(
                      autofocus: true,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      onSubmitted: (val) {
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
                          Navigator.pop(context);
                        },
                      ),
                      new FlatButton(
                        child: const Text('RENAME'),
                        onPressed: () {
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
                        },
                      )
                    ],
                  ),
            );
    }

    // to show dialogue to ensure of deleting operation
    bool status = false;
    _showConfirmDialog() async {
      _isIOS(context)
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text('Are you sure?'),
                    actions: <Widget>[
                      new CupertinoDialogAction(
                        child: const Text('CANCEL'),
                        onPressed: () {
                          Navigator.pop(context);
                          status = false;
                        },
                      ),
                      new CupertinoDialogAction(
                        child: const Text(
                          'OK',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          status = true;
                        },
                      )
                    ],
                  ),
            )
          : await showDialog<String>(
              context: context,
              builder: (BuildContext context) => new AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    content: new Container(
                      child: Text('Are you sure?'),
                    ),
                    actions: <Widget>[
                      new FlatButton(
                          child: const Text('CANCEL'),
                          onPressed: () {
                            Navigator.pop(context);
                            status = false;
                          }),
                      new FlatButton(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.pop(context);
                            status = true;
                          })
                    ],
                  ),
            );
    }

    _deleteHome(Home home) async {
      await _showConfirmDialog();
      if (status) {
        setState(() {
          _isLoading = true;
        });
        await _presenter.doDeleteHome(home);
      }
    }

    Widget createListView(BuildContext context, List<Home> homeList) {
      var len = 0;
      if (homeList != null) {
        len = homeList.length;
      }
      return new GridView.count(
        crossAxisCount: 2,
        // Generate 100 Widgets that display their index in the List
        children: List.generate(len + 1, (index) {
          if (index == len) {
            return Center(
                child: SizedBox(
              width: 150.0,
              height: 150.0,
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
            ));
          }
          return Center(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomeObject(home: homeList[index])),
                );
              },
              splashColor: kHAutoBlue300,
              child: Container(
                padding: EdgeInsets.only(left: 10.0, top: 20.0, bottom: 20.0),
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
                              style: Theme.of(context).textTheme.headline,
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
        }),
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
            if (index == len) {
              return Center(
                  child: SizedBox(
                width: 150.0,
                height: 150.0,
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
              ));
            }
            return Center(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            HomeObject(home: homeList[index])),
                  );
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
                                style: Theme.of(context).textTheme.headline,
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
        appBar: _isIOS(context)
            ? CupertinoNavigationBar(
                backgroundColor: kHAutoBlue100,
                leading: Container(),
                middle: new Text("Home Automation"),
                trailing: GetLogOut(),
              )
            : new AppBar(
                leading: Container(),
                title: new Text("Home Automation"),
                actions: <Widget>[
                  GetLogOut(),
                ],
              ),
        body: _isLoading
            ? ShowProgress()
            : _isIOS(context)
                ? new CustomScrollView(
                    slivers: <Widget>[
                      new CupertinoSliverRefreshControl(onRefresh: getHomeList),
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
                  ),
      ),
    );
  }
}

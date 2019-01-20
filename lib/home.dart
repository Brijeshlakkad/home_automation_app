import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/home_object.dart';
import 'package:home_automation/logout.dart';

class HomeScreen extends StatefulWidget {
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
  bool _autoValidateHomeName = false;
  bool _autoValidateHomeReName = false;
  var homeRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  List<Home> homeList = new List<Home>();
  var db = new DatabaseHelper();
  String _homeName;
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
  @override
  void onSuccess(Home home) async {
    _showSnackBar("Created ${home.toString()} home");
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.saveHome(home);
  }

  @override
  void onSuccessGetAllHome(List<Home> homeList) async {
    if (homeList != null) {
      _showSnackBar("Got ${homeList.length}");
      setState(() => _isLoading = false);
      var db = new DatabaseHelper();
      await db.saveAllHome(homeList);
    }
  }

  void onSuccessDelete(Home home) async {
    _showSnackBar(home.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.deleteHome(home);
    homeRefreshIndicatorKey.currentState?.show();
  }

  void onSuccessRename(Home home) async {
    _showSnackBar(home.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.renameHome(home);
    homeRefreshIndicatorKey.currentState?.show();
  }

  @override
  void onError(String errorTxt) {
    print("x");
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  Widget showProgress() {
    return Container(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future getHomeList() async {
    homeRefreshIndicatorKey.currentState?.show();
    homeList = await _presenter.api.getAllHome();
    if (homeList != null) {
      setState(() {
        homeList = homeList.toList();
      });
      onSuccessGetAllHome(homeList);
    }
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

    homeValidator(String val) {
      if (val.isEmpty) {
        return 'Please enter home name';
      } else if (existHomeName(val)) {
        return 'Home already exists';
      } else {
        return null;
      }
    }

    _showHomeNameDialog() async {
      await showDialog<String>(
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
                        validator: homeValidator,
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
      await showDialog<String>(
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
                        validator: homeValidator,
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
                    })
              ],
            ),
      );
    }

    // to show dialogue to ensure of deleting operation
    bool status = false;
    _showConfirmDialog() async {
      await showDialog<String>(
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
              child: Card(
                child: Container(
                  padding: EdgeInsets.only(left: 10.0, top: 20.0, bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Hero(
                          tag: homeList[index].id,
                          child: SizedBox(
                            width: 100.0,
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
                          FlatButton(
                            onPressed: () async {
                              await _showHomeReNameDialog(homeList[index]);
                            },
                            child: Icon(Icons.edit),
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          FlatButton(
                            onPressed: () async {
                              await _deleteHome(homeList[index]);
                            },
                            child: Icon(Icons.delete),
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

    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        leading: Container(),
        title: new Text("Home Automation"),
        actions: <Widget>[
          GetLogOut(),
        ],
      ),
      body: _isLoading
          ? showProgress()
          : RefreshIndicator(
              key: homeRefreshIndicatorKey,
              child: createListView(context, homeList),
              onRefresh: getHomeList,
            ),
    );
  }
}

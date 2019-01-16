import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/home_object.dart';

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() {
    return new HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> implements HomeScreenContract {
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  var refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  List<Home> homeList = new List<Home>();
  var db = new DatabaseHelper();
  TextEditingController _homeNameController, _homeReNameController;
  void _showSnackBar(String text) {
    scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    _homeNameController = new TextEditingController();
    _homeReNameController = new TextEditingController();
    getHomeList();
    setState(() => _isLoading = true);
    _presenter.doGetAllHome();
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
    refreshIndicatorKey.currentState.show();
  }

  @override
  void onSuccessGetAllHome(List<Home> homeList) async {
    if(homeList!=null){
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
    refreshIndicatorKey.currentState.show();
  }

  void onSuccessRename(Home home) async {
    _showSnackBar(home.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.renameHome(home);
    refreshIndicatorKey.currentState.show();
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
    refreshIndicatorKey.currentState?.show();
    homeList = await _presenter.api.getAllHome();
    if (homeList != null) {
      setState(() {
        homeList = homeList.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void getLogOut() async {
      var db = new DatabaseHelper();
      await db.deleteUsers();
      print("logout");
      Navigator.of(context).pushNamed('/login');
    }

    _createHome(String homeName) async {
      await _presenter.doCreateHome(homeName);
      _homeNameController.clear();
    }

    _renameHome(Home home, String homeName) async {
      await _presenter.doRenameHome(home, homeName);
      _homeReNameController.clear();
    }

    Future<List> getListOfHomeName() async {
      var db = new DatabaseHelper();
      List<Home> list = await db.getAllHome();
      if (list != null) {
        List homeNameList = new List();
        for (int i = 0; i < list.length; i++) {
          homeNameList.add(list[i].homeName);
        }
        return homeNameList;
      }
      return null;
    }

    existHomeName(String homeName) async {
      List list = await getListOfHomeName();
      if (list == null) {
        return false;
      }
      for (int i = 0; i < list.length; i++) {
        if (homeName == list[i]) return true;
      }
      return false;
    }

    validateHomeName(String homeName) async {
      Map validate = new Map();
      validate['error'] = true;
      validate['errorMessege'] = null;
      if (homeName.isEmpty) {
        validate['errorMessege'] = 'Please enter home name';
      } else if (await existHomeName(homeName)) {
        validate['errorMessege'] = 'Home exists';
      } else {
        validate['error'] = false;
        validate['errorMessege'] = null;
      }
      return validate;
    }

    _showHomeNameDialog() async {
      _homeNameController.clear();
      await showDialog<String>(
        context: context,
        builder: (BuildContext context) => new AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new TextField(
                      controller: _homeNameController,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Home',
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
                      Navigator.pop(context);
                      var res =
                          await validateHomeName(_homeNameController.text);
                      if (res['error']) {
                        _showSnackBar("${res['errorMessege']}");
                      } else {
                        setState(() {
                          _isLoading = true;
                        });
                        _createHome(_homeNameController.text);
                      }
                      _homeNameController.clear();
                    })
              ],
            ),
      );
    }

    _showHomeReNameDialog(Home home) async {
      _homeReNameController.text = home.homeName;
      await showDialog<String>(
        context: context,
        builder: (BuildContext context) => new AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new TextField(
                      controller: _homeReNameController,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Home',
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
                    onPressed: () async {
                      Navigator.pop(context);
                      var res =
                          await validateHomeName(_homeReNameController.text);
                      if (res['error']) {
                        _showSnackBar("${res['errorMessege']}");
                      } else {
                        setState(() {
                          _isLoading = true;
                        });
                        _renameHome(home, _homeReNameController.text);
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

    _renameHomeName(Home home) async {
      await _showHomeReNameDialog(home);
      if (status) {
        setState(() {
          _isLoading = true;
        });
        await _presenter.doRenameHome(home, _homeReNameController.text);
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
                        child: Text(
                          '${homeList[index].homeName}',
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.headline,
                        ),
                      ),
                      SizedBox(
                        height: 40.0,
                      ),
                      Row(
                        children: <Widget>[
                          FlatButton(
                            onPressed: () async {
                              await _renameHomeName(homeList[index]);
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
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: getLogOut,
          ),
        ],
      ),
      body: _isLoading
          ? showProgress()
          : RefreshIndicator(
              key: refreshIndicatorKey,
              child: createListView(context, homeList),
              onRefresh: getHomeList,
            ),
    );
  }
}

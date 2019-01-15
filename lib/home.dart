import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() {
    return new HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> implements HomeScreenContract {
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  TextEditingController _homeNameController, _homeReNameController;
  void _showSnackBar(String text) {
    scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    _homeNameController = new TextEditingController();
    _homeReNameController = new TextEditingController();
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

  void onSuccessDelete(Home home) async {
    _showSnackBar(home.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.deleteHome(home);
  }
  void onSuccessRename(Home home) async {
    _showSnackBar(home.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.renameHome(home);
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

    _renameHome(Home home) async {
      await _presenter.doRenameHome(home);
      _homeReNameController.clear();
    }

    Future<List> getListOfHomeName() async {
      var db = new DatabaseHelper();
      List<Map> list = await db.getAllHome();
      List homeNameList = new List();
      for (int i = 0; i < list.length; i++) {
        homeNameList.add(list[i]['homeName']);
      }
      return homeNameList;
    }

    existHomeName(String homeName) async {
      List list = await getListOfHomeName();
      for (int i = 0; i < list.length; i++) {
        if (homeName == list[i]) return true;
      }
      return false;
    }

    validateHomeName(String homeName) async {
      Map validate = new Map();
      validate['error'] = true;
      validate['errorMessege'] = null;
      print("f");
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
                      setState(() {
                        if (res['error']) {
                          _showSnackBar("${res['errorMessege']}");
                        } else {
                          _isLoading = true;
                          _createHome(_homeNameController.text);
                        }
                        _homeNameController.clear();
                      });
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
                    child: const Text('CREATE'),
                    onPressed: () async {
                      Navigator.pop(context);
                      var res =
                          await validateHomeName(_homeReNameController.text);
                      setState(() {
                        if (res['error']) {
                          _showSnackBar("${res['errorMessege']}");
                        } else {
                          _isLoading = true;
                          _renameHome(home);
                        }
                        _homeReNameController.clear();
                      });
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
        await _presenter.doRenameHome(home);
      }
    }

    Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
      List<Map> values = snapshot.data;
      var len=0;
      if(values!=null){
        len=values.length;
      }
      return new GridView.count(
        crossAxisCount: 2,
        // Generate 100 Widgets that display their index in the List
        children: List.generate(len + 1, (index) {
          if (values==null || index == len) {
            return Center(
                child: SizedBox(
              width: 150.0,
              height: 150.0,
              child: RaisedButton(
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(30.0)),
                onPressed: _showHomeNameDialog,
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
          Home home = Home.map(values[index]);
          return Center(
            child: Card(
              child: Container(
                padding: EdgeInsets.only(left: 10.0, top: 20.0, bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${values[index]['homeName']}',
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.headline,
                      ),
                    ),
                    SizedBox(
                      height: 40.0,
                    ),
                    Row(
                      children: <Widget>[
                        FloatingActionButton(
                          onPressed: () async {
                            await _renameHomeName(home);
                          },
                          child: Icon(Icons.edit),
                        ),
                        SizedBox(
                          width: 10.0,
                        ),
                        FloatingActionButton(
                          backgroundColor: Colors.red,
                          onPressed: () async {
                            await _deleteHome(home);
                          },
                          child: Icon(Icons.delete),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    }

    var db = new DatabaseHelper();

    var getHome = new FutureBuilder(
      future: db.getAllHome(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return showProgress();
          default:
            if (snapshot.hasError)
              return new Text('Error: ${snapshot.error}');
            else {
              return createListView(context, snapshot);
            }
        }
      },
    );

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
      body: _isLoading ? showProgress() : getHome,
    );
  }
}

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
  TextEditingController _homeNameController;
  void _showSnackBar(String text) {
    scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    _homeNameController = new TextEditingController();
    super.initState();
  }

  HomeScreenPresenter _presenter;
  HomeScreenState() {
    _presenter = new HomeScreenPresenter(this);
  }
  @override
  void onSuccess(Home home) async {
    _showSnackBar(home.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.saveHome(home);
  }

  @override
  void onError(String errorTxt) {
    print("x");
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }
  Widget showProgress(){
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
    _showDialog() async {
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
                  decoration: new InputDecoration(labelText: 'Home'),
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
                  setState(() {
                    _isLoading=true;
                  });
                 await _presenter.doCreateHome(_homeNameController.text);
                  _homeNameController.clear();
                })
          ],
        ),
      );
    }
    Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
      List<Map> values = snapshot.data;
      return new GridView.count(
        crossAxisCount: 2,
        // Generate 100 Widgets that display their index in the List
        children: List.generate(values.length + 1, (index) {
          if (index == values.length) {
            return Center(
                child: SizedBox(
                  width: 150.0,
                  height: 150.0,
                  child: RaisedButton(
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(30.0)),
                    onPressed: _showDialog,
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
            child: Text(
              'Home ${values[index]['homeName']}',
              style: Theme.of(context).textTheme.headline,
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
            return CircularProgressIndicator();
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
      body: _isLoading ? showProgress() :getHome,
    );
  }
}


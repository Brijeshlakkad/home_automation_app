import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/home_data.dart';


class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() {
    return new HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> {
  TextEditingController _homeNameController;
  @override
  void initState() {
    _homeNameController=new TextEditingController();
    super.initState();
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
        child: new AlertDialog(
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
                child: const Text('Create'),
                onPressed: () async{
                  Navigator.pop(context);
                  CreateHome api=new CreateHome();
                  try {
                    var home = await api.create(_homeNameController.text);
                    print("success");
                  } on Exception catch(error) {
                    print('Error');
                  }
                })
          ],
        ),
      );
    }

    var addHomeInterface = new Container(
      padding: EdgeInsets.only(left: 40.0, top: 30.0),
      child: Row(
        children: <Widget>[
          RaisedButton(
            onPressed: _showDialog,
            color: kHAutoBlue300,
            elevation: 10.0,
            child: Icon(
              Icons.add,
              color: Colors.black,
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 30.0),
            child: Text(
              'Add Home',
              style: TextStyle(fontSize: 21.0),
            ),
          )
        ],
      ),
    );
    return new Scaffold(
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
      body: addHomeInterface,
    );
  }
}

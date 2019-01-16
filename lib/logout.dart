import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
class GetLogOut extends StatefulWidget{
  @override
  GetLogOutState createState() {
    return new GetLogOutState();
  }
}

class GetLogOutState extends State<GetLogOut> {
  @override
  Widget build(BuildContext context) {
    getLogOut() async {
      var db = new DatabaseHelper();
      await db.deleteUsers();
      print("logout");
      Navigator.of(context).pushNamed('/login');
    }
    return IconButton(
      icon: Icon(Icons.clear),
      onPressed: getLogOut,
    );
  }
}
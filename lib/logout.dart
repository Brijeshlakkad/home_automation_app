import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';

class GetLogOut extends StatefulWidget {
  @override
  GetLogOutState createState() {
    return new GetLogOutState();
  }
}

class GetLogOutState extends State<GetLogOut> {
  bool _isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    getLogOut() async {
      var db = new DatabaseHelper();
      await db.deleteUsers();
      print("logout");
      Navigator.popUntil(context, ModalRoute.withName('/'));
      Navigator.pushNamed(context, "/logout");
    }

    return _isIOS(context)
        ? FlatButton(
            onPressed: getLogOut,
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.black),
            ),
          )
        : IconButton(
            icon: Icon(Icons.clear),
            onPressed: getLogOut,
          );
  }
}

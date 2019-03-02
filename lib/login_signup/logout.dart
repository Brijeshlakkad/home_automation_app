import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';

class GetLogOut extends StatefulWidget {
  @override
  GetLogOutState createState() {
    return new GetLogOutState();
  }
}

class GetLogOutState extends State<GetLogOut> implements LogoutScreenContract {
  LogoutScreenPresenter _presenter;
  GetLogOutState() {
    _presenter = new LogoutScreenPresenter(this);
  }
  @override
  void onLogoutError(String errorTxt) {}

  @override
  void onLogoutSuccess() async {}
  @override
  Widget build(BuildContext context) {
    getLogOut() async {
      _presenter.doLogout(context);
    }

    return Container(
      color: Colors.red,
      child: FlatButton(
        onPressed: getLogOut,
        child: Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

abstract class LogoutScreenContract {
  void onLogoutSuccess();
  void onLogoutError(String error);
}

class LogoutScreenPresenter {
  LogoutScreenContract _view;
  // RestDatasource api = new RestDatasource();
  LogoutScreenPresenter(this._view);

  doLogout(BuildContext context) async {
    try {
      var db = new DatabaseHelper();
      await db.deleteUsers();
      Navigator.pushNamed(context, "/login");
      //var user = await api.logout(email, password);
      _view.onLogoutSuccess();
    } on Exception catch (error) {
      _view.onLogoutError(error.toString());
    }
  }
}

import 'dart:async';
import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/models/user.dart';

class RestDatasource {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://86d2ad5a.ngrok.io/Home Automation';
  static final loginURL = baseURL + "/login_data.php";
  static final _apiKEY = "somerandomkey";

  Future<User> login(String username, String password) {
    return _netUtil.post(loginURL, body: {
      "token": _apiKEY,
      "email": username,
      "password": password
    }).then((dynamic res) {
      print(res.toString());
      if(res["error"]) throw new Exception(res["errorMessege"].toString());
      return new User.map(res["user"]);
    });
  }
}
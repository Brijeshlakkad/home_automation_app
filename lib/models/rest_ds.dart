import 'dart:async';
import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/models/user_data.dart';

class RestDatasource {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://homeautomations.tk/brijesh/server_files';
  static final loginURL = baseURL + "/login_data.php";
  static final signupURL = baseURL + "/signup_data.php";
  static final _apiKEY = "somerandomkey";

  Future<User> login(String email, String password) {
    return _netUtil.post(loginURL, body: {
      "token": _apiKEY,
      "email": email,
      "password": password
    }).then((dynamic res) {
      print(res.toString());
      if(res["error"]) throw new Exception(res["errorMessege"].toString());
      return new User.map(res["user"]);
    });
  }

  Future<Null> signup(String name, String email, String password, String address, String city, String contact) {
    return _netUtil.post(signupURL, body: {
      "token": _apiKEY,
      "name": name,
      "email": email,
      "password": password,
      "address": address,
      "city": city,
      "contact": contact
    }).then((dynamic res) {
      print(res.toString());
      if(res["error"]) throw new Exception(res["errorMessege"].toString());
      return null;
    });
  }
}
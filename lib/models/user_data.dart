import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/utils/network_util.dart';
//class User {
//  String _email;
//  String _password;
//  User(this._email, this._password);
//
//  User.map(dynamic obj) {
//    this._email = obj["email"];
//    this._password = obj["password"];
//  }
//
//  String get email => _email;
//  String get password => _password;
//
//  Map<String, dynamic> toMap() {
//    var map = new Map<String, dynamic>();
//    map["email"] = _email;
//    map["password"] = _password;
//    return map;
//  }
//}

class User {
  int _id;
  String _email, _password, _name, _city, _address, _mobile;
  User(this_id,this._email, this._password, this._name, this._city, this._mobile,
      this._address);

  User.map(dynamic obj) {
    this._id = int.parse(obj['id'].toString());
    this._email = obj["email"];
    this._password = obj["password"];
    this._name = obj["name"];
    this._city = obj["city"];
    this._mobile = obj["mobile"];
    this._address = obj["address"];
  }
  int get id => _id;
  String get email => _email;
  String get password => _password;
  String get name => _name;
  String get city => _city;
  String get mobile => _mobile;
  String get type => _address;

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['id'] = _id;
    map["email"] = _email;
    map["password"] = _password;
    map["name"] = _name;
    map["city"] = _city;
    map["mobile"] = _mobile;
    map["address"] = _address;
    return map;
  }

  @override
  String toString() {
    return "User $name";
  }
}

class RequestUser {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://homeautomations.tk/brijesh/server_files';
  static final finalURL = baseURL + "/user_actions.php";
  static final db = new DatabaseHelper();
  Future<User> getUserDetails(String user) async {
    return _netUtil.post(finalURL, body: {"email": user, "action": "0"}).then(
        (dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessage"]);
      return User.map(res['user']);
    });
  }

  Future updateUser(email, name, city, mobile) async {
    return _netUtil.post(finalURL, body: {
      "email": email,
      "name": name,
      "city": city,
      "mobile": mobile,
      "action": "5"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessage"]);
      return User.map(res['user']);
    });
  }
}

abstract class UserContract {
  void onUserSuccess(User userDetails);
  void onUserError();
}

class UserPresenter {
  UserContract _view;
  RequestUser api = new RequestUser();
  UserPresenter(this._view);

  doGetUser(String userEmail) async {
    try {
      var user = await api.getUserDetails(userEmail);
      if (user == null) {
        _view.onUserError();
      } else {
        _view.onUserSuccess(user);
      }
    } on Exception catch (error) {
      print(error.toString());
      _view.onUserError();
    }
  }
}

abstract class UserUpdateContract {
  void onUserUpdateSuccess(User userDetails);
  void onUserUpdateError(String errorString);
}

class UserUpdatePresenter {
  UserUpdateContract _view;
  RequestUser api = new RequestUser();
  UserUpdatePresenter(this._view);

  doUpdateUser(email, name, city, mobile) async {
    try {
      var user = await api.updateUser(email, name, city, mobile);
      if (user == null) {
        _view.onUserUpdateError("Update Failed");
      } else {
        _view.onUserUpdateSuccess(user);
      }
    } on Exception catch (error) {
      _view.onUserUpdateError(error.toString());
    }
  }
}

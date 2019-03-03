import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/utils/custom_exception.dart';

class Home {
  String _homeName, _email;
  int _id;
  Home(this._homeName, this._email, this._id);
  Home.map(dynamic obj) {
    this._homeName = obj["homeName"];
    this._email = obj["email"];
    var id = obj['id'].toString();
    this._id = int.parse(id);
  }

  String get homeName => _homeName;
  String get email => _email;
  int get id => _id;
  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["homeName"] = _homeName;
    map["email"] = _email;
    map['id'] = _id;
    return map;
  }

  @override
  String toString() {
    return homeName;
  }
}

class SendHomeData {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://homeautomations.tk/brijesh/server_files';
  static final finalURL = baseURL + "/home_actions.php";
  static final db = new DatabaseHelper();
  Future<List<Home>> getAllHome() async {
    final user = await db.getUser();
    return _netUtil.post(finalURL, body: {"email": user, "action": "0"}).then(
        (dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      int total = int.parse(res['total'].toString());
      List<Home> homeList = new List<Home>();
      for (int i = 0; i < total; i++) {
        homeList.add(Home.map(res['user']['home'][i]));
      }
      return homeList;
    });
  }

  Future<Home> create(String homeName) async {
    final user = await db.getUser();
    return _netUtil.post(finalURL, body: {
      "homeName": homeName,
      "email": user,
      "action": "1"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return new Home.map(res['user']['home']);
    });
  }

  Future<Home> delete(Home home) async {
    final user = home.email;
    final id = home.id.toString();
    return _netUtil.post(finalURL,
        body: {"email": user, "action": "2", "id": id}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return home;
    });
  }

  Future<Home> rename(Home home, String homeName) async {
    final user = home.email;
    final id = home.id.toString();
    return _netUtil.post(finalURL, body: {
      "homeName": homeName,
      "email": user,
      "action": "3",
      "id": id
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      home._homeName = homeName;
      return home;
    });
  }
}

abstract class HomeScreenContract {
  void onSuccess(Home home);
  void onSuccessDelete(Home home);
  void onError(String errorTxt);
  void onSuccessRename(Home home);
}

class HomeScreenPresenter {
  HomeScreenContract _view;
  SendHomeData api = new SendHomeData();
  HomeScreenPresenter(this._view);

  doCreateHome(String homeName) async {
    try {
      var home = await api.create(homeName);
      _view.onSuccess(home);
    } on Exception catch (error) {
      _view.onError(error.toString());
    }
  }

  doDeleteHome(Home home) async {
    try {
      var h = await api.delete(home);
      _view.onSuccessDelete(h);
    } on Exception catch (error) {
      _view.onError(error.toString());
    }
  }

  doRenameHome(Home home, String homeName) async {
    try {
      var h = await api.rename(home, homeName);
      _view.onSuccessRename(h);
    } on Exception catch (error) {
      _view.onError(error.toString());
    }
  }
}

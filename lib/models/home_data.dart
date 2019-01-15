import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/data/database_helper.dart';

class Home {
  String _homeName, _email;
  int _id;
  Home(this._homeName, this._email);
  Home.map(dynamic obj) {
    this._homeName = obj["homeName"];
    this._email = obj["email"];
    this._id = obj['id'];
  }

  String get homeName => _homeName;
  String get email => _email;
  int get id => _id;
  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["homeName"] = _homeName;
    map["email"] = _email;
    if(_id != null){
      map['id']=_id;
    }
    return map;
  }
  @override
  String toString() {
    // TODO: implement toString
    return homeName;
  }
}
class HomeConst{
  final Home home;
  const HomeConst({this.home});
}
class SendHomeData {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://86d2ad5a.ngrok.io/Home Automation';
  static final finalURL = baseURL + "/create_home.php";
  static final db = new DatabaseHelper();
  Future<Home> create(String homeName) async {
    final user = await db.getUser();
    return _netUtil.post(finalURL,
        body: {"homeName": homeName, "email": user, "create": "1"}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return new Home.map(res);
    });
  }

  Future<Home> delete(Home home) async {
    final user =home.email;
    final homeName= home.homeName;
    return _netUtil.post(finalURL,
        body: {"homeName": homeName, "email": user, "delete": "2"}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return new Home.map(res);
    });
  }
}

abstract class HomeScreenContract {
  void onSuccess(Home home);
  void onSuccessDelete(Home home);
  void onError(String errorTxt);
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
      print('Error');
    }
  }
  doDeleteHome(Home home) async{
    try {
      var h = await api.delete(home);
      _view.onSuccessDelete(h);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }
}

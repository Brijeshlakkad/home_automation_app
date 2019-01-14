import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/data/database_helper.dart';

class Home {
  String _homeName;
  Home(this._homeName);

  Home.map(dynamic obj) {
    this._homeName = obj["homeName"];
  }

  String get homeName => _homeName;

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["homeName"] = _homeName;
    return map;
  }
}

class CreateHome {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://86d2ad5a.ngrok.io/Home Automation';
  static final finalURL = baseURL + "/create_home.php";
  static final db = new DatabaseHelper();
  Future<Home> create(String homeName) async{
    final user = await db.getUser();
    return _netUtil.post(finalURL,
        body: {"homeName": homeName, "email": user}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"].toString());
      return new Home.map(res["homeName"]);
    });
  }
}

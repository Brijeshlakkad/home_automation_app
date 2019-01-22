import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/models/room_data.dart';

class Hardware {
  String _hwName, _email, _hwIP, _hwSeries;
  int _id, _homeID, _roomID;
  Hardware(this._hwName, this._hwSeries, this._hwIP, this._roomID, this._email,
      this._homeID, this._id);
  Hardware.map(dynamic obj) {
    this._hwName = obj["hwName"];
    this._hwSeries = obj["hwSeries"];
    this._hwIP = obj["hwIP"];
    this._email = obj["email"];
    var id = obj['id'].toString();
    this._id = int.parse(id);
    var homeID = obj['homeID'].toString();
    this._homeID = int.parse(homeID);
    var roomID = obj['roomID'].toString();
    this._roomID = int.parse(roomID);
  }

  String get hwName => _hwName;
  String get hwSeries => _hwSeries;
  String get hwIP => _hwIP;
  String get email => _email;
  int get id => _id;
  int get homeID => _homeID;
  int get roomID => _roomID;
  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["hwName"] = _hwName;
    map["hwSeries"] = _hwSeries;
    map["hwIP"] = _hwIP;
    map["email"] = _email;
    map['homeID'] = _homeID;
    map['roomID'] = _roomID;
    map['id'] = _id;
    return map;
  }

  @override
  String toString() {
    return hwName;
  }
}

class SendHardwareData {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://homeautomations.tk/brijesh/server_files';
  static final finalURL = baseURL + "/hardware_actions.php";
  static final db = new DatabaseHelper();

  Future<List<Hardware>> getAllHardware(Room room) async {
    final user = room.email;
    final homeID = room.homeID.toString();
    final roomID = room.id.toString();
    return _netUtil.post(finalURL, body: {
      "email": user,
      "homeID": homeID,
      "roomID": roomID,
      "action": "0"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      int total = int.parse(res['total'].toString());
      List<Hardware> roomList = new List<Hardware>();
      for (int i = 0; i < total; i++) {
        roomList.add(Hardware.map(res['user']['hw'][i]));
      }
      return roomList;
    });
  }

  Future<Hardware> create(
      String hwName, String hwSeries, String hwIP, Room room) async {
    final user = room.email;
    final homeID = room.homeID.toString();
    final roomID = room.id.toString();
    return _netUtil.post(finalURL, body: {
      "hwName": hwName,
      "hwSeries": hwSeries,
      "hwIP": hwIP,
      "email": user,
      "homeID": homeID,
      "roomID": roomID,
      "action": "1"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return new Hardware.map(res['user']['hw']);
    });
  }

  Future<Hardware> delete(Hardware hw) async {
    final user = hw.email;
    final id = hw.id.toString();
    return _netUtil.post(finalURL,
        body: {"email": user, "id": id, "action": "2"}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return hw;
    });
  }

  Future<Hardware> rename(
      Hardware hw, String hwName, String hwSeries, String hwIP) async {
    final user = hw.email;
    final id = hw.id.toString();
    return _netUtil.post(finalURL, body: {
      "hwName": hwName,
      "hwSeries": hwSeries,
      "hwIP": hwIP,
      "email": user,
      "action": "3",
      "id": id
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      hw._hwName = hwName;
      return hw;
    });
  }
}

abstract class HardwareScreenContract {
  void onSuccess(Hardware hw);
  void onSuccessDelete(Hardware hw);
  void onError(String errorTxt);
  void onSuccessRename(Hardware hw);
  void onSuccessGetAllHardware(List<Hardware> hwList);
}

class HardwareScreenPresenter {
  HardwareScreenContract _view;
  SendHardwareData api = new SendHardwareData();
  HardwareScreenPresenter(this._view);

  doCreateHardware(
      String hwName, String hwSeries, String hwIP, Room room) async {
    try {
      var hw = await api.create(hwName, hwSeries, hwIP, room);
      _view.onSuccess(hw);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }

  doDeleteHardware(Hardware hw) async {
    try {
      var w = await api.delete(hw);
      _view.onSuccessDelete(w);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }

  doRenameHardware(
      Hardware hw, String hwName, String hwSeries, String hwIP) async {
    try {
      var r = await api.rename(hw, hwName, hwSeries, hwIP);
      _view.onSuccessRename(r);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }

  doGetAllHardware(Room room) async {
    try {
      List<Hardware> hwList = await api.getAllHardware(room);
      _view.onSuccessGetAllHardware(hwList);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }
}

import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/models/hardware_data.dart';

class Device {
  String _dvName, _email, _dvPort, _dvImg;
  int _id, _homeID, _roomID, _hwID, _dvStatus;
  Device(this._dvName, this._dvPort, this._dvImg, this._dvStatus, this._email,
      this._roomID, this._homeID, this._hwID, this._id);
  Device.map(dynamic obj) {
    this._dvName = obj["dvName"];
    this._dvPort = obj["dvPort"];
    this._dvImg = obj['dvImg'];
    this._email = obj["email"];
    var id = obj['id'].toString();
    this._id = int.parse(id);
    var homeID = obj['homeID'].toString();
    this._homeID = int.parse(homeID);
    var roomID = obj['roomID'].toString();
    this._roomID = int.parse(roomID);
    var hwID = obj['hwID'].toString();
    this._hwID = int.parse(hwID);
    var dvStatus = obj['dvStatus'].toString();
    this._dvStatus = int.parse(dvStatus);
  }

  String get dvName => _dvName;
  String get dvPort => _dvPort;
  String get dvImg => _dvImg;
  String get email => _email;
  int get dvStatus => _dvStatus;
  int get id => _id;
  int get homeID => _homeID;
  int get roomID => _roomID;
  int get hwID => _hwID;
  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["dvName"] = _dvName;
    map["dvPort"] = _dvPort;
    map["dvImg"] = _dvImg;
    map["dvStatus"] = _dvStatus;
    map["email"] = _email;
    map['homeID'] = _homeID;
    map['roomID'] = _roomID;
    map['hwID'] = _hwID;
    map['id'] = _id;
    return map;
  }

  @override
  String toString() {
    return dvName;
  }
}
class DeviceImg {
  String _key;
  String _value;
  DeviceImg(this._key, this._value);
  String get key => _key;
  String get value => _value;
  DeviceImg.map(dynamic obj) {
    this._key = obj["key"];
    this._value = obj["value"];
  }
  Map<String, String> toMap() {
    var map = new Map<String, String>();
    map["key"] = _key;
    map["value"] = _value;
    return map;
  }
  @override
  String toString() {
    return value;
  }
}

class SendDeviceData {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://86d2ad5a.ngrok.io/Home Automation';
  static final finalURL = baseURL + "/device_actions.php";
  static final db = new DatabaseHelper();

  Future<List<Device>> getAllDevice(Hardware hw) async {
    final user = hw.email;
    final homeID = hw.homeID.toString();
    final roomID = hw.roomID.toString();
    final hwID = hw.id.toString();
    return _netUtil.post(finalURL, body: {
      "email": user,
      "homeID": homeID,
      "roomID": roomID,
      "hwID": hwID,
      "action": "0"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      int total = int.parse(res['total'].toString());
      List<Device> dvList = new List<Device>();
      for (int i = 0; i < total; i++) {
        dvList.add(Device.map(res['user']['device'][i]));
      }
      return dvList;
    });
  }
  Future<List<DeviceImg>> getAllDeviceImg() async {
    return _netUtil.post(finalURL, body: {
      "action": "4"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      int total = int.parse(res['total'].toString());
      List<DeviceImg> dvImgList = new List<DeviceImg>();
      for (int i = 0; i < total; i++) {
        dvImgList.add(DeviceImg.map(res['user']['deviceImg'][i]));
      }
      return dvImgList;
    });
  }

  Future<Device> create(
      String dvName, String dvPort, String dvImg, Hardware hw) async {
    final user = hw.email;
    final homeID = hw.homeID.toString();
    final roomID = hw.roomID.toString();
    final hwID = hw.id.toString();
    return _netUtil.post(finalURL, body: {
      "dvName": dvName,
      "dvPort": dvPort,
      "dvImg": dvImg,
      "email": user,
      "homeID": homeID,
      "roomID": roomID,
      "hwID": hwID,
      "action": "1"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return new Device.map(res['user']);
    });
  }

  Future<Device> delete(Device dv) async {
    final user = dv.email;
    final id = dv.id.toString();
    return _netUtil.post(finalURL,
        body: {"email": user, "id": id, "action": "2"}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return dv;
    });
  }

  Future<Device> rename(
      Device dv, String dvName, String dvImg, String dvPort) async {
    final user = dv.email;
    final id = dv.id.toString();
    return _netUtil.post(finalURL, body: {
      "dvName": dvName,
      "dvPort": dvPort,
      "dvImg": dvImg,
      "email": user,
      "action": "3",
      "id": id
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      dv._dvName = dvName;
      dv._dvPort = dvPort;
      return dv;
    });
  }
}

abstract class DeviceScreenContract {
  void onSuccess(Device dv);
  void onSuccessDelete(Device dv);
  void onError(String errorTxt);
  void onSuccessRename(Device dv);
  void onSuccessGetAllDevice(List<Device> dvList);
}

class DeviceScreenPresenter {
  DeviceScreenContract _view;
  SendDeviceData api = new SendDeviceData();
  DeviceScreenPresenter(this._view);

  doCreateDevice(
      String dvName, String dvPort, String dvImg, Hardware hw) async {
    try {
      var dv = await api.create(dvName, dvPort, dvImg, hw);
      _view.onSuccess(dv);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }

  doDeleteDevice(Device dv) async {
    try {
      var d = await api.delete(dv);
      _view.onSuccessDelete(d);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }

  doRenameDevice(Device dv, String dvName, String dvPort, String dvImg) async {
    try {
      var d = await api.rename(dv, dvName, dvPort, dvImg);
      _view.onSuccessRename(d);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }

  doGetAllDevice(Hardware hw) async {
    try {
      List<Device> dvList = await api.getAllDevice(hw);
      _view.onSuccessGetAllDevice(dvList);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }
}

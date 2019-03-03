import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/models/hardware_data.dart';
import 'package:home_automation/utils/custom_exception.dart';
class Device {
  String _dvName, _email, _dvPort, _dvImg;
  int _id, _homeID, _roomID, _hwID, _dvStatus;
  DeviceSlider _deviceSlider;
  Device(this._dvName, this._dvPort, this._dvImg, this._dvStatus, this._email,
      this._roomID, this._homeID, this._hwID, this._id, this._deviceSlider);
  Device.map(dynamic obj) {
    this._dvName = obj["dvName"];
    this._dvPort = obj["dvPort"].toString();
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
    if(obj['deviceSlider']!="null"){
      this._deviceSlider=DeviceSlider.map(obj['deviceSlider']);
    }else{
      this._deviceSlider=null;
    }
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
  DeviceSlider get deviceSlider => _deviceSlider;
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
    if(_deviceSlider!=null){
      map['deviceSlider']=_deviceSlider.toMap();
    }else{
      map['deviceSlider']=null;
    }
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

class DeviceSlider {
  String _email;
  int _id;
  int _dvID;
  int _value;
  DeviceSlider(this._id, this._dvID, this._value, this._email);
  int get id => _id;
  int get value => _value;
  int get dvID => _dvID;
  String get email => _email;
  DeviceSlider.map(dynamic obj) {
    this._id = int.parse(obj["id"].toString());
    this._dvID = int.parse(obj['dvID'].toString());
    this._value = int.parse(obj["value"].toString());
    this._email = obj["email"];
  }
  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["id"] = _id;
    map['dvID'] = _dvID;
    map["value"] = _value;
    map["email"] = _email;
    return map;
  }

  @override
  String toString() {
    return value.toString();
  }
}

class SendDeviceData {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://homeautomations.tk/brijesh/server_files';
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
      if (res["error"]) throw new FormException(res["errorMessage"]);
      int total = int.parse(res['total'].toString());
      List<Device> dvList = new List<Device>();
      for (int i = 0; i < total; i++) {
        dvList.add(Device.map(res['user']['device'][i]));
      }
      return dvList;
    });
  }

  Future<List<DeviceImg>> getAllDeviceImg() async {
    return _netUtil.post(finalURL, body: {"action": "4"}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
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
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return new Device.map(res['user']['device']);
    });
  }

  Future<Device> delete(Device dv) async {
    final user = dv.email;
    final id = dv.id.toString();
    return _netUtil.post(finalURL,
        body: {"email": user, "id": id, "action": "2"}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
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
      if (res["error"]) throw new FormException(res["errorMessage"]);
      dv._dvName = dvName;
      dv._dvPort = dvPort;
      return dv;
    });
  }

  Future<Device> getDevice(Device dv) async {
    final user = dv.email;
    final dvID = dv.id.toString();
    return _netUtil.post(finalURL, body: {
      "email": user,
      "deviceID": dvID,
      "action": "5"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return Device.map(res['user']);
    });
  }

  Future<Device> changeDeviceStatus(Device dv, int status) async {
    final user = dv.email;
    final dvID = dv.id.toString();
    return _netUtil.post(finalURL, body: {
      "email": user,
      "deviceID": dvID,
      "status": status.toString(),
      "action": "6",
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return Device.map(res['user']);
    });
  }

  Future<DeviceSlider> changeDeviceSlider(DeviceSlider dvSlider, int val) async {
    final user = dvSlider.email;
    final dvID = dvSlider.dvID.toString();
    return _netUtil.post(finalURL, body: {
      "email": user,
      "deviceID": dvID,
      "value": val.toString(),
      "action": "7",
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      dvSlider._value=val;
    });
  }
}

abstract class DeviceScreenContract {
  void onSuccess(Device dv);
  void onSuccessDelete(Device dv);
  void onError(String errorTxt);
  void onSuccessRename(Device dv);
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
}

abstract class DeviceStatusScreenContract {
  void onSuccess(Device dv);
  void onError(String errorTxt);
}

class DeviceStatusScreenPresenter {
  DeviceStatusScreenContract _view;
  SendDeviceData api = new SendDeviceData();
  DeviceStatusScreenPresenter(this._view);

  doChangeDeviceStatus(Device dv, int status) async {
    try {
      var d = await api.changeDeviceStatus(dv, status);
      _view.onSuccess(d);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }
}

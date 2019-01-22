import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/models/home_data.dart';

class Room {
  String _roomName, _email;
  int _id, _homeID;
  Room(this._roomName, this._email, this._homeID, this._id);
  Room.map(dynamic obj) {
    this._roomName = obj["roomName"];
    this._email = obj["email"];
    var id = obj['id'].toString();
    this._id = int.parse(id);
    var homeID = obj['homeID'].toString();
    this._homeID = int.parse(homeID);
  }

  String get roomName => _roomName;
  String get email => _email;
  int get id => _id;
  int get homeID => _homeID;
  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["roomName"] = _roomName;
    map["email"] = _email;
    map['homeID'] = _homeID;
    map['id'] = _id;
    return map;
  }

  @override
  String toString() {
    return roomName;
  }
}

class SendRoomData {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://homeautomations.tk/brijesh/server_files';
  static final finalURL = baseURL + "/room_actions.php";
  static final db = new DatabaseHelper();

  Future<List<Room>> getAllRoom(Home home) async {
    final user = home.email;
    final homeID = home.id.toString();
    return _netUtil.post(finalURL, body: {
      "email": user,
      "homeID": homeID,
      "action": "0"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      int total = int.parse(res['total'].toString());
      List<Room> roomList = new List<Room>();
      for (int i = 0; i < total; i++) {
        roomList.add(Room.map(res['user']['room'][i]));
      }
      return roomList;
    });
  }

  Future<Room> create(String roomName, Home home) async {
    final homeID = home.id.toString();
    final user = home.email;
    return _netUtil.post(finalURL, body: {
      "roomName": roomName,
      "email": user,
      "homeID": homeID,
      "action": "1"
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return new Room.map(res['user']['room']);
    });
  }

  Future<Room> delete(Room room) async {
    final user = room.email;
    final id = room.id.toString();
    return _netUtil.post(finalURL,
        body: {"email": user, "id": id, "action": "2"}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return room;
    });
  }

  Future<Room> rename(Room room, String roomName) async {
    final user = room.email;
    final id = room.id.toString();
    return _netUtil.post(finalURL, body: {
      "roomName": roomName,
      "email": user,
      "action": "3",
      "id": id
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      room._roomName=roomName;
      return room;
    });
  }
}

abstract class RoomScreenContract {
  void onSuccess(Room room);
  void onSuccessDelete(Room room);
  void onError(String errorTxt);
  void onSuccessRename(Room room);
  void onSuccessGetAllRoom(List<Room> roomList);
}

class RoomScreenPresenter {
  RoomScreenContract _view;
  SendRoomData api = new SendRoomData();
  RoomScreenPresenter(this._view);

  doCreateRoom(String roomName, Home home) async {
    try {
      var room = await api.create(roomName, home);
      _view.onSuccess(room);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }

  doDeleteRoom(Room room) async {
    try {
      var r = await api.delete(room);
      _view.onSuccessDelete(r);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }

  doRenameRoom(Room room, String roomName) async {
    try {
      var r = await api.rename(room, roomName);
      _view.onSuccessRename(r);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }

  doGetAllRoom(Home home) async {
    try {
      List<Room> r = await api.getAllRoom(home);
      _view.onSuccessGetAllRoom(r);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }
}

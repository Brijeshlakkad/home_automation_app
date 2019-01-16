import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/models/home_data.dart';
class Room {
  String _roomName, _email;
  int _id, _homeID;
  Room(this._roomName, this._email,this._homeID);
  Room.map(dynamic obj) {
    this._roomName = obj["roomName"];
    this._email = obj["email"];
    var id= obj['id'].toString();
    this._id=int.parse(id);
    var homeID= obj['homeID'].toString();
    this._homeID=int.parse(homeID);
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
    if(_id != null){
      map['id']=_id;
    }
    return map;
  }
  @override
  String toString() {
    return roomName;
  }
}
class SendRoomData {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://86d2ad5a.ngrok.io/Home Automation';
  static final finalURL = baseURL + "/room_actions.php";
  static final db = new DatabaseHelper();
  Future<Room> create(String roomName, Home home) async {
    final homeID=home.id.toString();
    final user = home.email;
    return _netUtil.post(finalURL,
        body: {"roomName": roomName, "email": user, "homeID": homeID, "action": "1"}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return new Room.map(res['user']);
    });
  }

  Future<Room> delete(Room room) async {
    final homeID=room.homeID.toString();
    final user =room.email;
    final id=room.id.toString();
    final roomName= room.roomName;
    return _netUtil.post(finalURL,
        body: {"roomName": roomName, "email": user, "homeID": homeID, "id":id, "action": "2"}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return new Room.map(res['user']);
    });
  }
  Future<Room> rename(Room room,String roomName) async {
    final user =room.email;
    final id=room.id.toString();
    final homeID=room.homeID.toString();
    return _netUtil.post(finalURL,
        body: {"roomName": roomName, "homeID": homeID,"email": user, "action": "3", "id":id}).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new Exception(res["errorMessege"]);
      return new Room.map(res['user']);
    });
  }
}

abstract class RoomScreenContract {
  void onSuccess(Room room);
  void onSuccessDelete(Room room);
  void onError(String errorTxt);
  void onSuccessRename(Room room);
}

class RoomScreenPresenter {
  RoomScreenContract _view;
  SendRoomData api = new SendRoomData();
  RoomScreenPresenter(this._view);

  doCreateRoom(String roomName, Home home) async {
    try {
      var room = await api.create(roomName,home);
      _view.onSuccess(room);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }
  doDeleteRoom(Room room) async{
    try {
      var r = await api.delete(room);
      print("1");
      _view.onSuccessDelete(r);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }
  doRenameRoom(Room room,String roomName) async{
    try {
      var r = await api.rename(room,roomName);
      print("3");
      _view.onSuccessRename(r);
    } on Exception catch (error) {
      _view.onError(error.toString());
      print('Error');
    }
  }
}
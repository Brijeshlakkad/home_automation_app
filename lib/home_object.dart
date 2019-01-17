import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/logout.dart';

class HomeObject extends StatefulWidget {
  final Home home;
  const HomeObject({this.home});
  @override
  HomeObjectState createState() {
    return new HomeObjectState();
  }
}

class HomeObjectState extends State<HomeObject> {
  @override
  Widget build(BuildContext context) {
    return ShowRoomsOfHome(
      home: widget.home,
    );
  }
}

class ShowRoomsOfHome extends StatefulWidget {
  final Home home;
  const ShowRoomsOfHome({this.home});
  @override
  ShowRoomsOfHomeState createState() {
    return new ShowRoomsOfHomeState();
  }
}

class ShowRoomsOfHomeState extends State<ShowRoomsOfHome>
    implements RoomScreenContract {
  final showRoomscaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  var refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  List<Room> roomList = new List<Room>();
  TextEditingController _roomNameController, _roomReNameController;
  void _showSnackBar(String text) {
    showRoomscaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    _roomNameController = new TextEditingController();
    _roomReNameController = new TextEditingController();
    getRoomList();
    refreshIndicatorKey.currentState?.show();
    super.initState();
  }

  var db = new DatabaseHelper();

  Future getRoomList() async {
    refreshIndicatorKey.currentState?.show();
    roomList = await _presenter.api.getAllRoom(widget.home);
    if (roomList != null) {
      setState(() {
        roomList = roomList.toList();
      });
    }
  }

  RoomScreenPresenter _presenter;
  ShowRoomsOfHomeState() {
    _presenter = new RoomScreenPresenter(this);
  }
  @override
  void onSuccess(Room room) async {
    _showSnackBar("Created ${room.toString()} home");
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.saveRoom(room);
    refreshIndicatorKey.currentState?.show();
  }

  @override
  void onSuccessGetAllRoom(List<Room> roomList) async {
    if(roomList!=null){
      _showSnackBar("Got ${roomList.length}");
      setState(() => _isLoading = false);
      var db = new DatabaseHelper();
      await db.saveAllRoom(roomList);
    }
  }

  void onSuccessDelete(Room room) async {
    print("1");
    _showSnackBar(room.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.deleteRoom(room);
    refreshIndicatorKey.currentState?.show();
  }

  void onSuccessRename(Room room) async {
    _showSnackBar(room.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.renameRoom(room);
    refreshIndicatorKey.currentState?.show();
  }

  @override
  void onError(String errorTxt) {
    print("x");
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    _createRoom(String roomName, Home home) async {
      await _presenter.doCreateRoom(roomName, home);
      _roomNameController.clear();
    }

    _renameRoom(Room room, String roomName) async {
      await _presenter.doRenameRoom(room, roomName);
      _roomReNameController.clear();
    }

    Future<List> getListOfRoomName() async {
      var db = new DatabaseHelper();
      List<Room> list = await db.getAllRoom();
      if (list != null) {
        List roomNameList = new List();
        for (int i = 0; i < list.length; i++) {
          roomNameList.add(list[i].roomName);
        }
        return roomNameList;
      }
      return null;
    }

    existRoomName(String roomName) async {
      List list = await getListOfRoomName();
      if (list == null) {
        return false;
      }
      for (int i = 0; i < list.length; i++) {
        if (roomName == list[i]) return true;
      }
      return false;
    }

    validateRoomName(String roomName) async {
      Map validate = new Map();
      validate['error'] = true;
      validate['errorMessege'] = null;
      if (roomName.isEmpty) {
        validate['errorMessege'] = 'Please enter room name';
      } else if (await existRoomName(roomName)) {
        validate['errorMessege'] = 'Room already exists';
      } else {
        validate['error'] = false;
        validate['errorMessege'] = null;
      }
      return validate;
    }

    _showRoomNameDialog() async {
      _roomNameController.clear();
      await showDialog<String>(
        context: context,
        builder: (BuildContext context) => new AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new TextField(
                      controller: _roomNameController,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Room',
                      ),
                    ),
                  )
                ],
              ),
              actions: <Widget>[
                new FlatButton(
                    child: const Text('CANCEL'),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                new FlatButton(
                    child: const Text('CREATE'),
                    onPressed: () async {
                      Navigator.pop(context);
                      var res =
                          await validateRoomName(_roomNameController.text);
                      if (res['error']) {
                        _showSnackBar("${res['errorMessege']}");
                      } else {
                        setState(() {
                          _isLoading = true;
                        });
                        _createRoom(_roomNameController.text, widget.home);
                      }
                      _roomNameController.clear();
                    })
              ],
            ),
      );
    }

    _showRoomReNameDialog(Room room) async {
      _roomReNameController.text = room.roomName;
      await showDialog<String>(
        context: context,
        builder: (BuildContext context) => new AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new TextField(
                      controller: _roomReNameController,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Home',
                      ),
                    ),
                  )
                ],
              ),
              actions: <Widget>[
                new FlatButton(
                    child: const Text('CANCEL'),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                new FlatButton(
                    child: const Text('RENAME'),
                    onPressed: () async {
                      Navigator.pop(context);
                      var res =
                          await validateRoomName(_roomReNameController.text);
                      if (res['error']) {
                        _showSnackBar("${res['errorMessege']}");
                      } else {
                        setState(() {
                          _isLoading = true;
                        });
                        _renameRoom(room, _roomReNameController.text);
                      }
                    })
              ],
            ),
      );
    }

    // to show dialogue to ensure of deleting operation
    bool status = false;
    _showConfirmDialog() async {
      await showDialog<String>(
        context: context,
        builder: (BuildContext context) => new AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: new Container(
                child: Text('Are you sure?'),
              ),
              actions: <Widget>[
                new FlatButton(
                    child: const Text('CANCEL'),
                    onPressed: () {
                      Navigator.pop(context);
                      status = false;
                    }),
                new FlatButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.pop(context);
                      status = true;
                    })
              ],
            ),
      );
    }

    _deleteRoom(Room room) async {
      await _showConfirmDialog();
      if (status) {
        setState(() {
          _isLoading = true;
        });
        await _presenter.doDeleteRoom(room);
      }
    }

    _renameRoomName(Room room) async {
      await _showRoomReNameDialog(room);
      if (status) {
        setState(() {
          _isLoading = true;
        });
        await _presenter.doRenameRoom(room, _roomReNameController.text);
      }
    }

    Widget createListView(BuildContext context, List<Room> roomList) {
      var len = 0;
      if (roomList != null) {
        len = roomList.length;
      }
      return new GridView.count(
        crossAxisCount: 2,
        // Generate 100 Widgets that display their index in the List
        children: List.generate(len + 1, (index) {
          if (index == len) {
            return Center(
                child: SizedBox(
              width: 150.0,
              height: 150.0,
              child: RaisedButton(
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(30.0)),
                onPressed: () async {
                  await _showRoomNameDialog();
                },
                color: kHAutoBlue300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.add),
                    Text('Add Room'),
                  ],
                ),
              ),
            ));
          }
          return Center(
            child: InkWell(
              onTap: () {},
              splashColor: kHAutoBlue300,
              child: Card(
                child: Container(
                  padding: EdgeInsets.only(left: 10.0, top: 20.0, bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${roomList[index].roomName}',
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.headline,
                        ),
                      ),
                      SizedBox(
                        height: 40.0,
                      ),
                      Row(
                        children: <Widget>[
                          FlatButton(
                            onPressed: () async {
                              await _renameRoomName(roomList[index]);
                            },
                            child: Icon(Icons.edit),
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          FlatButton(
                            onPressed: () async {
                              await _deleteRoom(roomList[index]);
                            },
                            child: Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    return new Scaffold(
      key: showRoomscaffoldKey,
      appBar: new AppBar(
        title: new Text("Home: ${widget.home.homeName}"),
        actions: <Widget>[
          GetLogOut(),
        ],
      ),
      body: _isLoading
          ? ShowProgress()
          : RefreshIndicator(
              key: refreshIndicatorKey,
              child: createListView(context, roomList),
              onRefresh: getRoomList,
            ),
    );
  }
}

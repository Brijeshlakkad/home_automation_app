import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/logout.dart';
import 'package:home_automation/hardware.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/internet_access.dart';

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
  final showRoomScaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  var roomNameFormKey = new GlobalKey<FormState>();
  var roomReNameFormKey = new GlobalKey<FormState>();
  bool _autoValidateRoomName = false;
  bool _autoValidateRoomReName = false;
  String _roomName;
  var roomRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  List<Room> roomList = new List<Room>();
  bool internetAccess = false;
  var db = new DatabaseHelper();
  void _showSnackBar(String text) {
    showRoomScaffoldKey.currentState.removeCurrentSnackBar();
    showRoomScaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });
    getRoomList();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getRoomList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      roomRefreshIndicatorKey.currentState?.show();
      roomList = await _presenter.api.getAllRoom(widget.home);
      if (roomList != null) {
        setState(() {
          roomList = roomList.toList();
        });
        onSuccessGetAllRoom(roomList);
      }
    } else {
      setState(() {
        roomList = new List<Room>();
        _isLoading = false;
      });
      _showSnackBar("Please check internet connection");
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
//    var db = new DatabaseHelper();
//    await db.saveRoom(room);
    getRoomList();
  }

  @override
  void onSuccessGetAllRoom(List<Room> roomList) async {
    if (roomList != null) {
      _showSnackBar("Got ${roomList.length}");
      setState(() => _isLoading = false);
//      var db = new DatabaseHelper();
//      await db.saveAllRoom(roomList);
    }
  }

  @override
  void onSuccessDelete(Room room) async {
    _showSnackBar("Deleted ${room.roomName} room");
    setState(() => _isLoading = false);
//    var db = new DatabaseHelper();
//    await db.deleteRoom(room);
    getRoomList();
  }

  @override
  void onSuccessRename(Room room) async {
    _showSnackBar(room.toString());
    setState(() => _isLoading = false);
//    var db = new DatabaseHelper();
//    await db.renameRoom(room);
    getRoomList();
  }

  @override
  void onError(String errorTxt) {
    print("x");
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  bool _isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    _createRoom(String roomName, Home home) async {
      await _presenter.doCreateRoom(roomName, home);
    }

    _renameRoom(Room room, String roomName) async {
      await _presenter.doRenameRoom(room, roomName);
    }

    List getListOfRoomName() {
      List<Room> list = roomList;
      if (list != null) {
        List roomNameList = new List();
        for (int i = 0; i < list.length; i++) {
          roomNameList.add(list[i].roomName);
        }
        return roomNameList;
      }
      return null;
    }

    existRoomName(String roomName) {
      List list = getListOfRoomName();
      if (list == null) {
        return false;
      }
      for (int i = 0; i < list.length; i++) {
        if (roomName == list[i]) return true;
      }
      return false;
    }

    roomValidator(String val, String ignoreName) {
      if (val.isEmpty) {
        return 'Please enter room name';
      } else if (existRoomName(val) && val != ignoreName) {
        return 'Room already exists';
      } else {
        return null;
      }
    }

    _showRoomNameDialog() async {
      _isIOS(context)
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Create Room Here"),
                    content: CupertinoTextField(
                      autofocus: true,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      onSubmitted: (val) {
                        if (roomValidator(val, null) == null) {
                          Navigator.pop(context);
                          setState(() {
                            _isLoading = true;
                          });
                          _createRoom(val, widget.home);
                        } else {
                          Navigator.pop(context);
                          _showSnackBar("${roomValidator(val, null)}");
                        }
                      },
                    ),
                  ),
            )
          : await showDialog<String>(
              context: context,
              builder: (BuildContext context) => new AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    content: new Row(
                      children: <Widget>[
                        new Expanded(
                          child: Form(
                            key: roomNameFormKey,
                            autovalidate: _autoValidateRoomName,
                            child: new TextFormField(
                              validator: (val) => roomValidator(val, null),
                              onSaved: (val) => _roomName = val,
                              autofocus: true,
                              decoration: new InputDecoration(
                                labelText: 'Room',
                              ),
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
                          onPressed: () {
                            var form = roomNameFormKey.currentState;
                            if (form.validate()) {
                              form.save();
                              Navigator.pop(context);
                              setState(() {
                                _isLoading = true;
                                _autoValidateRoomName = false;
                              });
                              _createRoom(_roomName, widget.home);
                            } else {
                              setState(() {
                                _autoValidateRoomName = true;
                              });
                            }
                          })
                    ],
                  ),
            );
    }

    _showRoomReNameDialog(Room room) async {
      _isIOS(context)
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Modify Your Room Name Here"),
                    content: CupertinoTextField(
                      autofocus: true,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      onSubmitted: (val) {
                        if (val != room.roomName) {
                          if (roomValidator(val, room.roomName) == null) {
                            Navigator.pop(context);
                            setState(() {
                              _isLoading = true;
                            });
                            _renameRoom(room, val);
                          } else {
                            Navigator.pop(context);
                            _showSnackBar(
                                "${roomValidator(val, room.roomName)}");
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
            )
          : await showDialog<String>(
              context: context,
              builder: (BuildContext context) => new AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    content: new Row(
                      children: <Widget>[
                        new Expanded(
                          child: Form(
                            key: roomReNameFormKey,
                            autovalidate: _autoValidateRoomReName,
                            child: new TextFormField(
                              validator: (val) =>
                                  roomValidator(val, room.roomName),
                              initialValue: room.roomName,
                              onSaved: (val) => _roomName = val,
                              autofocus: true,
                              decoration: new InputDecoration(
                                labelText: 'Room',
                              ),
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
                          onPressed: () {
                            var form = roomReNameFormKey.currentState;
                            if (form.validate()) {
                              form.save();
                              Navigator.pop(context);
                              setState(() {
                                _isLoading = true;
                                _autoValidateRoomReName = false;
                              });
                              _renameRoom(room, _roomName);
                            } else {
                              setState(() {
                                _autoValidateRoomReName = true;
                              });
                            }
                          })
                    ],
                  ),
            );
    }

    // to show dialogue to ensure of deleting operation
    bool status = false;
    _showConfirmDialog() async {
      _isIOS(context)
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text('Are you sure?'),
                    actions: <Widget>[
                      new CupertinoDialogAction(
                        child: const Text('CANCEL'),
                        onPressed: () {
                          Navigator.pop(context);
                          status = false;
                        },
                      ),
                      new CupertinoDialogAction(
                        child: const Text(
                          'OK',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          status = true;
                        },
                      )
                    ],
                  ),
            )
          : await showDialog<String>(
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HardwareScreen(
                          home: widget.home, room: roomList[index])),
                );
              },
              splashColor: kHAutoBlue300,
              child: Container(
                padding: EdgeInsets.only(
                    left: 10.0, top: 20.0, bottom: 20.0, right: 10.0),
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Hero(
                          tag: roomList[index].roomName,
                          child: Padding(
                            padding: EdgeInsets.only(left: 15.0, top: 10.0),
                            child: Text(
                              '${roomList[index].roomName}',
                              textAlign: TextAlign.left,
                              style: Theme.of(context).textTheme.headline,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40.0,
                      ),
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: 40.0,
                            child: FlatButton(
                              onPressed: () async {
                                await _showRoomReNameDialog(roomList[index]);
                              },
                              child: Icon(Icons.edit),
                            ),
                          ),
                          SizedBox(
                            width: 20.0,
                          ),
                          SizedBox(
                            width: 40.0,
                            child: FlatButton(
                              onPressed: () async {
                                await _deleteRoom(roomList[index]);
                              },
                              child: Icon(Icons.delete),
                            ),
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

    Widget createListViewIOS(BuildContext context, List<Room> roomList) {
      var len = 0;
      if (roomList != null) {
        len = roomList.length;
      }
      return new SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 1.0,
          crossAxisCount: 2,
        ),
        delegate: new SliverChildBuilderDelegate(
          (BuildContext context, int index) {
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HardwareScreen(
                            home: widget.home, room: roomList[index])),
                  );
                },
                splashColor: kHAutoBlue300,
                child: Container(
                  padding: EdgeInsets.only(
                      left: 10.0, top: 20.0, bottom: 20.0, right: 10.0),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Hero(
                            tag: roomList[index].roomName,
                            child: Padding(
                              padding: EdgeInsets.only(left: 15.0, top: 10.0),
                              child: Text(
                                '${roomList[index].roomName}',
                                textAlign: TextAlign.left,
                                style: Theme.of(context).textTheme.headline,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 40.0,
                        ),
                        Row(
                          children: <Widget>[
                            SizedBox(
                              width: 40.0,
                              child: FlatButton(
                                onPressed: () async {
                                  await _showRoomReNameDialog(roomList[index]);
                                },
                                child: Icon(Icons.edit),
                              ),
                            ),
                            SizedBox(
                              width: 20.0,
                            ),
                            SizedBox(
                              width: 40.0,
                              child: FlatButton(
                                onPressed: () async {
                                  await _deleteRoom(roomList[index]);
                                },
                                child: Icon(Icons.delete),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: len + 1,
        ),
      );
    }

    return new Scaffold(
      key: showRoomScaffoldKey,
      appBar: _isIOS(context)
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Home',
                      style: Theme.of(context).textTheme.headline,
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                    new Hero(
                      tag: widget.home.id,
                      child: SizedBox(
                        width: 100.0,
                        child: Text(
                          "${widget.home.homeName}",
                          style: Theme.of(context).textTheme.headline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: GetLogOut(),
            )
          : new AppBar(
              title: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Home',
                      style: Theme.of(context).textTheme.headline,
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                    new Hero(
                      tag: widget.home.homeName,
                      child: SizedBox(
                        width: 100.0,
                        child: Text(
                          "${widget.home.homeName}",
                          style: Theme.of(context).textTheme.headline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                GetLogOut(),
              ],
            ),
      body: _isLoading
          ? ShowProgress()
          : _isIOS(context)
              ? new CustomScrollView(
                  slivers: <Widget>[
                    new CupertinoSliverRefreshControl(onRefresh: getRoomList),
                    new SliverSafeArea(
                      top: false,
                      sliver: createListViewIOS(context, roomList),
                    ),
                  ],
                )
              : RefreshIndicator(
                  key: roomRefreshIndicatorKey,
                  child: createListView(context, roomList),
                  onRefresh: getRoomList,
                ),
    );
  }
}

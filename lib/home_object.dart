import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/show_progress.dart';
class HomeObject extends StatefulWidget{
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
    return ShowRoomsOfHome(home: widget.home,);
  }
}

class ShowRoomsOfHome extends StatefulWidget{
  final Home home;
  const ShowRoomsOfHome({this.home});
  @override
  ShowRoomsOfHomeState createState() {
    return new ShowRoomsOfHomeState();
  }
}

class ShowRoomsOfHomeState extends State<ShowRoomsOfHome>  implements RoomScreenContract{
  final showRoomscaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  TextEditingController _roomNameController, _roomReNameController;
  void _showSnackBar(String text) {
    showRoomscaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    _roomNameController = new TextEditingController();
    _roomReNameController = new TextEditingController();
    super.initState();
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
  }

  void onSuccessDelete(Room room) async {
    print("1");
    _showSnackBar(room.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.deleteRoom(room);
  }

  void onSuccessRename(Room room) async {
    _showSnackBar(room.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.renameRoom(room);
  }

  @override
  void onError(String errorTxt) {
    print("x");
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    void getLogOut() async {
      var db = new DatabaseHelper();
      await db.deleteUsers();
      await db.deleteDatabaseFile();
      print("logout");
      Navigator.of(context).pushNamed('/login');
    }

    _createRoom(String roomName,Home home) async {
      await _presenter.doCreateRoom(roomName,home);
      _roomNameController.clear();
    }

    _renameRoom(Room room,String roomName) async {
      await _presenter.doRenameRoom(room,roomName);
      _roomReNameController.clear();
    }

    Future<List> getListOfRoomName() async {
      var db = new DatabaseHelper();
      List<Map> list = await db.getAllRoom();
      if(list != null){
        List roomNameList = new List();
        for (int i = 0; i < list.length; i++) {
          roomNameList.add(list[i]['roomName']);
        }
        return roomNameList;
      }
      return null;
    }

    existRoomName(String roomName) async {
      List list = await getListOfRoomName();
      if(list == null){
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
                    _createRoom(_roomNameController.text,widget.home);
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
                    _renameRoom(room,_roomReNameController.text);
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
        await _presenter.doRenameRoom(room,_roomReNameController.text);
      }
    }

    Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
      List<Map> values;
      var len = 0;
      if(snapshot.data!=null || (snapshot.data is List)){
        values=snapshot.data;
        len = values.length;
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
                    onPressed: () async{
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
          Room room= Room.map(values[index]);
          return Center(
            child: InkWell(
              onTap: (){

              },
              splashColor: kHAutoBlue300,
              child: Card(
                child: Container(
                  padding: EdgeInsets.only(left: 10.0, top: 20.0, bottom: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${values[index]['roomName']}',
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
                              await _renameRoomName(room);
                            },
                            child: Icon(Icons.edit),
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          FlatButton(
                            onPressed: () async {
                              await _deleteRoom(room);
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

    var db = new DatabaseHelper();

    var getRoom = new FutureBuilder(
      future: db.getAllRoom(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return ShowProgress();
          default:
            if (snapshot.hasError)
              return new Text('Error: ${snapshot.error}');
            else {
              return createListView(context, snapshot);
            }
        }
      },
    );
    return new Scaffold(
      key: showRoomscaffoldKey,
      appBar: new AppBar(
        title: new Text("Home: ${widget.home.homeName}"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: getLogOut,
          ),
        ],
      ),
      body: _isLoading ? ShowProgress() : getRoom,
    );
  }
}
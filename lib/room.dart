import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/hardware.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/delete_confirmation.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/get_to_user_profile.dart';
import 'package:home_automation/utils/custom_services.dart';
import 'package:flutter/services.dart';

class RoomScreen extends StatefulWidget {
  final Home home;
  final User user;
  final Function callbackUser;
  const RoomScreen({this.user, this.callbackUser, this.home});
  @override
  RoomScreenState createState() {
    return new RoomScreenState(user, callbackUser);
  }
}

class RoomScreenState extends State<RoomScreen> implements RoomScreenContract {
  bool _isLoading = true;
  bool internetAccess = false;
  ShowDialog _showDialog;
  CheckPlatform _checkPlatform;
  DeleteConfirmation _deleteConfirmation;
  ShowInternetStatus _showInternetStatus;
  GoToUserProfile _goToUserProfile;
  CustomService _customService;

  List<Room> roomList = new List<Room>();
  String _roomName;
  var roomNameFormKey = new GlobalKey<FormState>();
  var roomReNameFormKey = new GlobalKey<FormState>();
  bool _autoValidateRoomName = false;
  bool _autoValidateRoomReName = false;

  final showRoomScaffoldKey = new GlobalKey<ScaffoldState>();
  var roomRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  void _showSnackBar(String text) {
    showRoomScaffoldKey.currentState.removeCurrentSnackBar();
    showRoomScaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  User user;
  Function callbackUser;
  Function callbackThis(User user) {
    this.callbackUser(user);
    setState(() {
      this.user = user;
    });
  }

  RoomScreenPresenter _presenter;
  RoomScreenState(user, callbackUser) {
    this.user = user;
    this.callbackUser = callbackUser;
    _presenter = new RoomScreenPresenter(this);
  }

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _customService = new CustomService();
    _showDialog = new ShowDialog();
    _deleteConfirmation = new DeleteConfirmation();
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    getRoomList();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccess = await checkInternetAccess.check();
    setState(() {
      this.internetAccess = internetAccess;
    });
  }

  Future getRoomList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      List<Room> roomList = await _presenter.api.getAllRoom(widget.home);
      if (roomList != null) {
        this.roomList = roomList.toList();
      } else {
        this.roomList = new List<Room>();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void onSuccess(Room room) async {
    _showDialog.showDialogCustom(context, "Success", "$room Rome created");
    getRoomList();
  }

  @override
  void onSuccessDelete(Room room) async {
    _showDialog.showDialogCustom(context, "Success", "$room Rome deleted");
    getRoomList();
  }

  @override
  void onSuccessRename(Room room) async {
    getRoomList();
  }

  @override
  void onError(String errorTxt) {
    _showDialog.showDialogCustom(context, "Error", errorTxt);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    _goToUserProfile = new GoToUserProfile(
        context: context,
        isIOS: _checkPlatform.isIOS(),
        user: user,
        callbackThis: this.callbackThis);
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
          roomNameList.add(list[i].roomName.toLowerCase());
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
      RegExp roomNamePattern = new RegExp(r"^(([A-Za-z]+)([1-9]*))$");
      if (val.isEmpty) {
        return 'Please enter room name.';
      } else if (!roomNamePattern.hasMatch(val) ||
          val.length < 3 ||
          val.length > 8) {
        return "Room Name invalid.";
      } else if (existRoomName(val.toLowerCase()) && val != ignoreName) {
        return '"${_customService.ucFirst(val)}" Room already exists.';
      } else {
        return null;
      }
    }

    _showRoomNameDialog() async {
      _checkPlatform.isIOS()
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Create Room Here"),
                    content: CupertinoTextField(
                      autofocus: true,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (val) async {
                        await getInternetAccessObject();
                        if (internetAccess) {
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
                        } else {
                          Navigator.pop(context);
                          this._showDialog.showDialogCustom(
                              context,
                              "Internet Connection Problem",
                              "Please check your internet connection",
                              fontSize: 17.0,
                              boxHeight: 58.0);
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
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (val) async {
                                await getInternetAccessObject();
                                if (internetAccess) {
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
                                } else {
                                  Navigator.pop(context);
                                  this._showDialog.showDialogCustom(
                                      context,
                                      "Internet Connection Problem",
                                      "Please check your internet connection",
                                      fontSize: 17.0,
                                      boxHeight: 58.0);
                                }
                              },
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
                        onPressed: () async {
                          await getInternetAccessObject();
                          if (internetAccess) {
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
                          } else {
                            Navigator.pop(context);
                            this._showDialog.showDialogCustom(
                                context,
                                "Internet Connection Problem",
                                "Please check your internet connection",
                                fontSize: 17.0,
                                boxHeight: 58.0);
                          }
                        },
                      ),
                    ],
                  ),
            );
    }

    _showRoomReNameDialog(Room room) async {
      _checkPlatform.isIOS()
          ? await showDialog<String>(
              context: context,
              builder: (BuildContext context) => CupertinoAlertDialog(
                    title: Text("Modify Your Room Name Here"),
                    content: CupertinoTextField(
                      autofocus: true,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (val) async {
                        await getInternetAccessObject();
                        if (internetAccess) {
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
                        } else {
                          Navigator.pop(context);
                          this._showDialog.showDialogCustom(
                              context,
                              "Internet Connection Problem",
                              "Please check your internet connection",
                              fontSize: 17.0,
                              boxHeight: 58.0);
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
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (val) async {
                                await getInternetAccessObject();
                                if (internetAccess) {
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
                                } else {
                                  Navigator.pop(context);
                                  this._showDialog.showDialogCustom(
                                      context,
                                      "Internet Connection Problem",
                                      "Please check your internet connection",
                                      fontSize: 17.0,
                                      boxHeight: 58.0);
                                }
                              },
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
                        onPressed: () async {
                          await getInternetAccessObject();
                          if (internetAccess) {
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
                          } else {
                            Navigator.pop(context);
                            this._showDialog.showDialogCustom(
                                context,
                                "Internet Connection Problem",
                                "Please check your internet connection",
                                fontSize: 17.0,
                                boxHeight: 58.0);
                          }
                        },
                      ),
                    ],
                  ),
            );
    }

    _deleteRoom(Room room) async {
      await getInternetAccessObject();
      if (internetAccess) {
        bool status = await _deleteConfirmation.showConfirmDialog(
            context, _checkPlatform.isIOS());
        if (status) {
          setState(() {
            _isLoading = true;
          });
          await _presenter.doDeleteRoom(room);
        }
      } else {
        this._showDialog.showDialogCustom(
            context,
            "Internet Connection Problem",
            "Please check your internet connection",
            fontSize: 17.0,
            boxHeight: 58.0);
      }
    }

    Widget _getRoomObject(List<Room> roomList, int index, int len) {
      if (index == len) {
        return Center(
            child: SizedBox(
          width: 130.0,
          height: 130.0,
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
          onTap: () async {
            await getInternetAccessObject();
            if (internetAccess) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HardwareScreen(
                        user: this.user,
                        callbackUser: this.callbackUser,
                        home: widget.home,
                        room: roomList[index])),
              );
            } else {
              this._showDialog.showDialogCustom(
                  context,
                  "Internet Connection Problem",
                  "Please check your internet connection",
                  fontSize: 17.0,
                  boxHeight: 58.0);
            }
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
                          style: Theme.of(context)
                              .textTheme
                              .headline
                              .copyWith(fontSize: 17.0),
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
    }

    Widget createListView(BuildContext context, List<Room> roomList) {
      var len = 0;
      if (roomList != null) {
        len = roomList.length;
      }
      return new GridView.count(
        crossAxisCount: 2,
        // Generate 100 Widgets that display their index in the List
        children: List.generate(
          len + 1,
          (index) {
            return _getRoomObject(roomList, index, len);
          },
        ),
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
            return _getRoomObject(roomList, index, len);
          },
          childCount: len + 1,
        ),
      );
    }

    return new Scaffold(
      key: showRoomScaffoldKey,
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Home',
                      style: Theme.of(context)
                          .textTheme
                          .headline
                          .copyWith(fontSize: 18.0),
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
                          style: Theme.of(context)
                              .textTheme
                              .headline
                              .copyWith(fontSize: 18.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: _goToUserProfile.showUser(),
            )
          : new AppBar(
              title: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Home',
                      style: Theme.of(context)
                          .textTheme
                          .headline
                          .copyWith(fontSize: 17.0),
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
                          style: Theme.of(context)
                              .textTheme
                              .headline
                              .copyWith(fontSize: 17.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                _goToUserProfile.showUser(),
              ],
            ),
      body: _isLoading
          ? ShowProgress()
          : internetAccess
              ? _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getRoomList),
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
                    )
              : _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getRoomList),
                        new SliverSafeArea(
                          top: false,
                          sliver: _showInternetStatus.showInternetStatus(
                            _checkPlatform.isIOS(),
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      key: roomRefreshIndicatorKey,
                      child: _showInternetStatus.showInternetStatus(
                        _checkPlatform.isIOS(),
                      ),
                      onRefresh: getRoomList,
                    ),
    );
  }
}

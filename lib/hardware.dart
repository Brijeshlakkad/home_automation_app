import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/models/hardware_data.dart';
import 'package:home_automation/device.dart';
import 'package:home_automation/get_hardware_details.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/delete_confirmation.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/get_to_user_profile.dart';
import 'package:home_automation/utils/custom_services.dart';

class HardwareScreen extends StatefulWidget {
  final Home home;
  final Room room;
  final User user;
  final Function callbackUser;
  const HardwareScreen({this.user, this.callbackUser, this.home, this.room});
  @override
  HardwareScreenState createState() {
    return new HardwareScreenState(user, callbackUser);
  }
}

class HardwareScreenState extends State<HardwareScreen>
    implements HardwareScreenContract {
  bool _isLoading = true;
  bool internetAccess = false;
  ShowDialog _showDialog;
  CheckPlatform _checkPlatform;
  DeleteConfirmation _deleteConfirmation;
  ShowInternetStatus _showInternetStatus;
  GoToUserProfile _goToUserProfile;
  CustomService _customService;

  String _hwName, _hwSeries, _hwIP;
  List<Hardware> hwList = new List<Hardware>();
  var hwFormKey = new GlobalKey<FormState>();
  var hwReFormKey = new GlobalKey<FormState>();
  bool _autoValidateHw = false;
  final showHwScaffoldKey = new GlobalKey<ScaffoldState>();
  var hwRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  FocusNode _hwNameNode = new FocusNode();
  FocusNode _hwSeriesNode = new FocusNode();
  FocusNode _hwIPNode = new FocusNode();

  void _showSnackBar(String text) {
    showHwScaffoldKey.currentState.removeCurrentSnackBar();
    showHwScaffoldKey.currentState
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

  HardwareScreenPresenter _presenter;
  HardwareScreenState(user, callbackUser) {
    this.user = user;
    this.callbackUser = callbackUser;
    _presenter = new HardwareScreenPresenter(this);
  }

  @override
  void initState() {
    _customService = new CustomService();
    _showDialog = new ShowDialog();
    _deleteConfirmation = new DeleteConfirmation();
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    getHardwareList();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getHardwareList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      List<Hardware> hwList = await _presenter.api.getAllHardware(widget.room);
      if (hwList != null) {
        this.hwList = hwList.toList();
      } else {
        this.hwList = new List<Hardware>();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void onSuccess(Hardware hw) async {
    _showDialog.showDialogCustom(context, "Success", "$hw Hardware created");
    getHardwareList();
  }

  @override
  void onSuccessDelete(Hardware hw) async {
    _showDialog.showDialogCustom(context, "Success", "$hw Hardware deleted");
    getHardwareList();
  }

  @override
  void onSuccessRename(Hardware hw) async {
    getHardwareList();
  }

  @override
  void onError(String errorTxt) {
    _showDialog.showDialogCustom(context, "Error", errorTxt);
    setState(() => _isLoading = false);
  }

  void _fieldFocusChange(
      BuildContext context, FocusNode current, FocusNode next) {
    current.unfocus();
    FocusScope.of(context).requestFocus(next);
  }

  @override
  Widget build(BuildContext context) {
    _goToUserProfile = new GoToUserProfile(
        context: context,
        isIOS: _checkPlatform.isIOS(),
        user: user,
        callbackThis: this.callbackThis);
    _createHardware(
        String hwName, String hwSeries, String hwIP, Room room) async {
      await _presenter.doCreateHardware(hwName, hwSeries, hwIP, room);
    }

    _renameHardware(
        Hardware hw, String hwName, String hwSeries, String hwIP) async {
      await _presenter.doRenameHardware(hw, hwName, hwSeries, hwIP);
    }

    List getListOfHardwareName() {
      List<Hardware> list = hwList;
      if (list != null) {
        List hwNameList = new List();
        for (int i = 0; i < list.length; i++) {
          hwNameList.add(list[i].hwName.toLowerCase());
        }
        return hwNameList;
      }
      return null;
    }

    existHardwareName(String hwName) {
      List list = getListOfHardwareName();
      if (list == null) {
        return false;
      }
      for (int i = 0; i < list.length; i++) {
        if (hwName == list[i]) return true;
      }
      return false;
    }

    hardwareNameValidator(String val, String ignoreName) {
      RegExp hwNamePattern = new RegExp(r"^([A-Za-z1-9]*)$");
      if (val.isEmpty) {
        return 'Please enter hardware name';
      } else if (!hwNamePattern.hasMatch(val) || val.length < 2) {
        return "Hardware Name invalid.";
      } else if (existHardwareName(val.toLowerCase()) && val != ignoreName) {
        return '"${_customService.ucFirst(val)}" Hardware already exists.';
      } else {
        return null;
      }
    }

    hardwareSeriesValidator(String val) {
      if (val.isEmpty) {
        return 'Please enter hardware series';
      } else {
        return null;
      }
    }

    hardwareIPValidator(String val) {
      if (val.isEmpty) {
        return 'Please enter hardware IP value';
      } else {
        return null;
      }
    }

    _showHardwareNameDialog() async {
      await showDialog<Null>(
        context: context,
        builder: (BuildContext context) => new AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: Container(
                width: double.maxFinite,
                child: new ListView(
                  children: <Widget>[
                    new Container(
                      child: Center(
                        child: Text("Hardware details"),
                      ),
                      padding: EdgeInsets.only(bottom: 20.0),
                    ),
                    Form(
                      key: hwFormKey,
                      autovalidate: _autoValidateHw,
                      child: Column(
                        children: <Widget>[
                          new TextFormField(
                            validator: (val) =>
                                hardwareNameValidator(val, null),
                            onSaved: (val) => _hwName = val,
                            autofocus: true,
                            focusNode: _hwNameNode,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (val) {
                              _fieldFocusChange(
                                  context, _hwNameNode, _hwSeriesNode);
                            },
                            decoration: new InputDecoration(
                              labelText: 'Hardware Name',
                            ),
                          ),
                          new TextFormField(
                            onSaved: (val) => _hwSeries = val,
                            autofocus: true,
                            validator: hardwareSeriesValidator,
                            focusNode: _hwSeriesNode,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (val) {
                              _fieldFocusChange(
                                  context, _hwSeriesNode, _hwIPNode);
                            },
                            decoration: new InputDecoration(
                              labelText: 'Hardware Series',
                            ),
                          ),
                          new TextFormField(
                            validator: hardwareIPValidator,
                            onSaved: (val) => _hwIP = val,
                            autofocus: true,
                            focusNode: _hwIPNode,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (val) async {
                              await getInternetAccessObject();
                              if (internetAccess) {
                                var form = hwFormKey.currentState;
                                if (form.validate()) {
                                  form.save();
                                  Navigator.pop(context);
                                  setState(() {
                                    _isLoading = true;
                                    _autoValidateHw = false;
                                  });
                                  _createHardware(
                                      _hwName, _hwSeries, _hwIP, widget.room);
                                } else {
                                  setState(() {
                                    _autoValidateHw = true;
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
                              labelText: 'Hardware IP',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                      var form = hwFormKey.currentState;
                      if (form.validate()) {
                        form.save();
                        Navigator.pop(context);
                        setState(() {
                          _isLoading = true;
                          _autoValidateHw = false;
                        });
                        _createHardware(_hwName, _hwSeries, _hwIP, widget.room);
                      } else {
                        setState(() {
                          _autoValidateHw = true;
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

    _deleteHardware(Hardware hw) async {
      await getInternetAccessObject();
      if (internetAccess) {
        bool status = await _deleteConfirmation.showConfirmDialog(
            context, _checkPlatform.isIOS());
        if (status) {
          setState(() {
            _isLoading = true;
          });
          await _presenter.doDeleteHardware(hw);
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

    Widget _getHardwareObject(List<Hardware> hwList, int index) {
      return Center(
        child: InkWell(
          onTap: () async {
            await getInternetAccessObject();
            if (internetAccess) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceScreen(
                        home: widget.home,
                        room: widget.room,
                        hardware: hwList[index],
                      ),
                ),
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
                      tag: hwList[index].hwName,
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.0, top: 10.0),
                        child: Text(
                          '${hwList[index].hwName}',
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
                            await getInternetAccessObject();
                            if (internetAccess) {
                              Map hwDetails = new Map();
                              hwDetails = hwList[index].toMap();
                              hwDetails['isModifying'] = true;
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GetHardwareDetails(
                                        room: widget.room,
                                        hwList: hwList,
                                        hwDetails: hwDetails,
                                      ),
                                ),
                              );
                              if (result != null && !result['error']) {
                                setState(() {
                                  _isLoading = true;
                                });
                                _renameHardware(hwList[index], result['hwName'],
                                    result['hwSeries'], result['hwIP']);
                              }
                            } else {
                              this._showDialog.showDialogCustom(
                                  context,
                                  "Internet Connection Problem",
                                  "Please check your internet connection",
                                  fontSize: 17.0,
                                  boxHeight: 58.0);
                            }
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
                            await _deleteHardware(hwList[index]);
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

    Widget createListView(BuildContext context, List<Hardware> hwList) {
      var len = 0;
      if (hwList != null) {
        len = hwList.length;
      }
      return new GridView.count(
        crossAxisCount: 2,
        // Generate 100 Widgets that display their index in the List
        children: List.generate(
          len + 1,
          (index) {
            if (index == len) {
              return Center(
                child: SizedBox(
                  width: 130.0,
                  height: 130.0,
                  child: RaisedButton(
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(30.0)),
                    onPressed: () async {
                      await _showHardwareNameDialog();
                    },
                    color: kHAutoBlue300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.add),
                        Text('Add Hardware'),
                      ],
                    ),
                  ),
                ),
              );
            }
            return _getHardwareObject(hwList, index);
          },
        ),
      );
    }

    Widget createListViewIOS(BuildContext context, List<Hardware> hwList) {
      var len = 0;
      if (hwList != null) {
        len = hwList.length;
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
                width: 130.0,
                height: 130.0,
                child: RaisedButton(
                  shape: new RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(30.0)),
                  onPressed: () async {
                    await getInternetAccessObject();
                    if (internetAccess) {
                      Map hwDetails = new Map();
                      hwDetails['isModifying'] = false;
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GetHardwareDetails(
                                room: widget.room,
                                hwList: hwList,
                                hwDetails: hwDetails,
                              ),
                        ),
                      );
                      if (result != null && !result['error']) {
                        setState(() {
                          _isLoading = true;
                        });
                        _createHardware(result['hwName'], result['hwSeries'],
                            result['hwIP'], widget.room);
                      }
                    } else {
                      this._showDialog.showDialogCustom(
                          context,
                          "Internet Connection Problem",
                          "Please check your internet connection",
                          fontSize: 17.0,
                          boxHeight: 58.0);
                    }
                  },
                  color: kHAutoBlue300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.add),
                      Text('Add Hardware'),
                    ],
                  ),
                ),
              ));
            }
            return _getHardwareObject(hwList, index);
          },
          childCount: len + 1,
        ),
      );
    }

    return Scaffold(
      key: showHwScaffoldKey,
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Room',
                      style: Theme.of(context)
                          .textTheme
                          .headline
                          .copyWith(fontSize: 18.0),
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                    new Hero(
                      tag: widget.room.id,
                      child: SizedBox(
                        width: 100.0,
                        child: Text(
                          "${widget.room.roomName}",
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
          : AppBar(
              title: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Room',
                      style: Theme.of(context)
                          .textTheme
                          .headline
                          .copyWith(fontSize: 17.0),
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                    new Hero(
                      tag: widget.room.roomName,
                      child: SizedBox(
                        width: 100.0,
                        child: Text(
                          "${widget.room.roomName}",
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
                            onRefresh: getHardwareList),
                        new SliverSafeArea(
                          top: false,
                          sliver: createListViewIOS(context, hwList),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      key: hwRefreshIndicatorKey,
                      child: createListView(context, hwList),
                      onRefresh: getHardwareList,
                    )
              : _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getHardwareList),
                        new SliverSafeArea(
                          top: false,
                          sliver: _showInternetStatus.showInternetStatus(
                            _checkPlatform.isIOS(),
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      key: hwRefreshIndicatorKey,
                      child: _showInternetStatus.showInternetStatus(
                        _checkPlatform.isIOS(),
                      ),
                      onRefresh: getHardwareList,
                    ),
    );
  }
}

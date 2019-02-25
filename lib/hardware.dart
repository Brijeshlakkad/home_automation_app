import 'package:flutter/material.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/logout.dart';
import 'package:home_automation/models/hardware_data.dart';
import 'package:home_automation/device.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/get_hardware_details.dart';
import 'package:home_automation/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';

class HardwareScreen extends StatefulWidget {
  final Home home;
  final Room room;
  const HardwareScreen({this.home, this.room});
  @override
  HardwareScreenState createState() {
    return new HardwareScreenState();
  }
}

class HardwareScreenState extends State<HardwareScreen>
    implements HardwareScreenContract {
  final showHwScaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  var hwFormKey = new GlobalKey<FormState>();
  var hwReFormKey = new GlobalKey<FormState>();
  bool _autoValidateHw = false;
  bool _autoValidateHwRe = false;
  var hwRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  List<Hardware> hwList = new List<Hardware>();
  String _hwName, _hwSeries, _hwIP;
  bool internetAccess = false;
  ShowDialog _showDialog;

  void _showSnackBar(String text) {
    showHwScaffoldKey.currentState.removeCurrentSnackBar();
    showHwScaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    _showDialog = new ShowDialog();
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
      hwRefreshIndicatorKey.currentState?.show();
      hwList = await _presenter.api.getAllHardware(widget.room);
      if (hwList != null) {
        hwList = hwList.toList();
      } else {
        hwList = new List<Hardware>();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  HardwareScreenPresenter _presenter;
  HardwareScreenState() {
    _presenter = new HardwareScreenPresenter(this);
  }
  @override
  void onSuccess(Hardware hw) async {
    _showSnackBar("Created ${hw.toString()} hardware");
    setState(() => _isLoading = false);
//    var db = new DatabaseHelper();
//    await db.saveHardware(hw);
    getHardwareList();
  }

  @override
  void onSuccessDelete(Hardware hw) async {
    _showSnackBar("Hardware ${hw.hwName} deleted");
    setState(() => _isLoading = false);
//    var db = new DatabaseHelper();
//    await db.deleteHardware(hw);
    getHardwareList();
  }

  @override
  void onSuccessRename(Hardware hw) async {
    _showSnackBar(hw.toString());
    setState(() => _isLoading = false);
//    var db = new DatabaseHelper();
//    await db.renameHardware(hw);
    getHardwareList();
  }

  @override
  void onError(String errorTxt) {
    //_showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  bool _isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS ? true : false;
  }

  @override
  Widget build(BuildContext context) {
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
          hwNameList.add(list[i].hwName);
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
      if (val.isEmpty) {
        return 'Please enter hardware name';
      } else if (existHardwareName(val) && val != ignoreName) {
        return 'Hardware already exists';
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
                            decoration: new InputDecoration(
                              labelText: 'Hardware Name',
                            ),
                          ),
                          new TextFormField(
                            onSaved: (val) => _hwSeries = val,
                            autofocus: true,
                            validator: hardwareSeriesValidator,
                            decoration: new InputDecoration(
                              labelText: 'Hardware Series',
                            ),
                          ),
                          new TextFormField(
                            validator: hardwareIPValidator,
                            onSaved: (val) => _hwIP = val,
                            autofocus: true,
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

    _showHardwareReNameDialog(Hardware hw) async {
      await showDialog<String>(
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
                      key: hwReFormKey,
                      autovalidate: _autoValidateHwRe,
                      child: Column(
                        children: <Widget>[
                          new TextFormField(
                            validator: (val) =>
                                hardwareNameValidator(val, hw.hwName),
                            initialValue: hw.hwName,
                            onSaved: (val) => _hwName = val,
                            autofocus: true,
                            decoration: new InputDecoration(
                              labelText: 'Hardware Name',
                            ),
                          ),
                          new TextFormField(
                            validator: hardwareSeriesValidator,
                            onSaved: (val) => _hwSeries = val,
                            autofocus: true,
                            initialValue: hw.hwSeries,
                            decoration: new InputDecoration(
                              labelText: 'Hardware Series',
                            ),
                          ),
                          new TextFormField(
                            onSaved: (val) => _hwIP = val,
                            autofocus: true,
                            validator: hardwareIPValidator,
                            initialValue: hw.hwIP,
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
                  child: const Text('MODIFY'),
                  onPressed: () async {
                    await getInternetAccessObject();
                    if (internetAccess) {
                      var form = hwReFormKey.currentState;
                      if (form.validate()) {
                        form.save();
                        if (_hwName != hw.hwName ||
                            _hwSeries != hw.hwSeries ||
                            _hwIP != hw.hwIP) {
                          Navigator.pop(context);
                          setState(() {
                            _isLoading = true;
                            _autoValidateHwRe = false;
                          });
                          _renameHardware(hw, _hwName, _hwSeries, _hwIP);
                        } else {
                          Navigator.pop(context);
                        }
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

    // to show dialogue to ensure of deleting operation
    Future<bool> _showConfirmDialog() async {
      bool status = false;
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
      return status;
    }

    _deleteHardware(Hardware hw) async {
      await getInternetAccessObject();
      if (internetAccess) {
        bool status = await _showConfirmDialog();
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
                width: 150.0,
                height: 150.0,
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
                                  await _showHardwareReNameDialog(
                                      hwList[index]);
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
                width: 150.0,
                height: 150.0,
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
                                  await getInternetAccessObject();
                                  if (internetAccess) {
                                    Map hwDetails = new Map();
                                    hwDetails = hwList[index].toMap();
                                    hwDetails['isModifying'] = true;
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            GetHardwareDetails(
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
                                      _renameHardware(
                                          hwList[index],
                                          result['hwName'],
                                          result['hwSeries'],
                                          result['hwIP']);
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
          },
          childCount: len + 1,
        ),
      );
    }

    Widget showInternetStatusIOS(BuildContext context) {
      return new SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 1.0,
          crossAxisCount: 1,
        ),
        delegate:
            new SliverChildBuilderDelegate((BuildContext context, int index) {
          return Container(
            child: Center(
              child: Text("Please check your internet connection"),
            ),
          );
        }, childCount: 1),
      );
    }

    Widget showInternetStatus(BuildContext context) {
      return new GridView.count(
        crossAxisCount: 1,
        // Generate 100 Widgets that display their index in the List
        children: List.generate(1, (index) {
          return Container(
            child: Center(
              child: Text("Please check your internet connection"),
            ),
          );
        }),
      );
    }

    return Scaffold(
      key: showHwScaffoldKey,
      appBar: _isIOS(context)
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Room',
                      style: Theme.of(context).textTheme.headline,
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
                          style: Theme.of(context).textTheme.headline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: GetLogOut(),
            )
          : AppBar(
              title: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Room',
                      style: Theme.of(context).textTheme.headline,
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
          : internetAccess
              ? _isIOS(context)
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
              : _isIOS(context)
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getHardwareList),
                        new SliverSafeArea(
                            top: false, sliver: showInternetStatusIOS(context)),
                      ],
                    )
                  : RefreshIndicator(
                      key: hwRefreshIndicatorKey,
                      child: showInternetStatus(context),
                      onRefresh: getHardwareList,
                    ),
    );
  }
}

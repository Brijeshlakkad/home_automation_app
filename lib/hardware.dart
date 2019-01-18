import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/logout.dart';
import 'package:home_automation/models/hardware_data.dart';
import 'package:home_automation/device.dart';

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
  final showHwscaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  var hwFormKey = new GlobalKey<FormState>();
  var hwReFormKey = new GlobalKey<FormState>();
  bool _autoValidatehw = false;
  bool _autoValidatehwRe = false;
  var hwRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  List<Hardware> hwList = new List<Hardware>();
  String _hwName, _hwSeries, _hwIP;
  void _showSnackBar(String text) {
    showHwscaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    getHardwareList();
    hwRefreshIndicatorKey.currentState?.show();
    super.initState();
  }

  var db = new DatabaseHelper();

  Future getHardwareList() async {
    hwRefreshIndicatorKey.currentState?.show();
    hwList = await _presenter.api.getAllHardware(widget.room);
    if (hwList != null) {
      setState(() {
        hwList = hwList.toList();
      });
      onSuccessGetAllHardware(hwList);
    }
  }

  HardwareScreenPresenter _presenter;
  HardwareScreenState() {
    _presenter = new HardwareScreenPresenter(this);
  }
  @override
  void onSuccess(Hardware hw) async {
    _showSnackBar("Created ${hw.toString()} hardware");
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.saveHardware(hw);
    hwRefreshIndicatorKey.currentState?.show();
  }

  @override
  void onSuccessGetAllHardware(List<Hardware> hwList) async {
    if (hwList != null) {
      _showSnackBar("Got ${hwList.length}");
      setState(() => _isLoading = false);
      var db = new DatabaseHelper();
      await db.saveAllHardware(hwList);
    }
  }

  @override
  void onSuccessDelete(Hardware hw) async {
    _showSnackBar(hw.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.deleteHardware(hw);
    hwRefreshIndicatorKey.currentState?.show();
  }

  @override
  void onSuccessRename(Hardware hw) async {
    _showSnackBar(hw.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.renameHardware(hw);
    hwRefreshIndicatorKey.currentState?.show();
  }

  @override
  void onError(String errorTxt) {
    print("x");
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
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

    hardwareNameValidator(String val) {
      if (val.isEmpty) {
        return 'Please enter hardware name';
      } else if (existHardwareName(val)) {
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
                      autovalidate: _autoValidatehw,
                      child: Column(
                        children: <Widget>[
                          new TextFormField(
                            validator: hardwareNameValidator,
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
                      var form = hwFormKey.currentState;
                      if (form.validate()) {
                        form.save();
                        Navigator.pop(context);
                        setState(() {
                          _isLoading = true;
                          _autoValidatehw = false;
                        });
                        _createHardware(_hwName, _hwSeries, _hwIP, widget.room);
                      } else {
                        setState(() {
                          _autoValidatehw = true;
                        });
                      }
                    })
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
                      autovalidate: _autoValidatehwRe,
                      child: Column(
                        children: <Widget>[
                          new TextFormField(
                            validator: hardwareNameValidator,
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
                      var form = hwReFormKey.currentState;
                      if (form.validate()) {
                        form.save();
                        Navigator.pop(context);
                        setState(() {
                          _isLoading = true;
                          _autoValidatehwRe = false;
                        });
                        _renameHardware(hw, _hwName, _hwSeries, _hwIP);
                      } else {
                        setState(() {
                          _autoValidatehw = true;
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

    _deleteHardware(Hardware hw) async {
      await _showConfirmDialog();
      if (status) {
        setState(() {
          _isLoading = true;
        });
        await _presenter.doDeleteHardware(hw);
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
              onTap: () {
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
                          '${hwList[index].hwName}',
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
                              await _showHardwareReNameDialog(hwList[index]);
                            },
                            child: Icon(Icons.edit),
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          FlatButton(
                            onPressed: () async {
                              await _deleteHardware(hwList[index]);
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

    return Scaffold(
      key: showHwscaffoldKey,
      appBar: AppBar(
        title: Text('Hardware'),
        actions: <Widget>[
          GetLogOut(),
        ],
      ),
      body: _isLoading
          ? ShowProgress()
          : RefreshIndicator(
              key: hwRefreshIndicatorKey,
              child: createListView(context, hwList),
              onRefresh: getHardwareList,
            ),
    );
  }
}

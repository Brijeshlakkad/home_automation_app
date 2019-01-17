import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/logout.dart';
import 'package:home_automation/models/hardware_data.dart';

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
  var refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  List<Hardware> hwList = new List<Hardware>();
  TextEditingController _hwNameController, _hwReNameController;
  TextEditingController _hwSeriesController, _hwReSeriesController;
  TextEditingController _hwIPController, _hwReIPController;
  void _showSnackBar(String text) {
    showHwscaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    _hwNameController = new TextEditingController();
    _hwReNameController = new TextEditingController();
    _hwSeriesController = new TextEditingController();
    _hwReSeriesController = new TextEditingController();
    _hwIPController = new TextEditingController();
    _hwReIPController = new TextEditingController();
    getHardwareList();
    _presenter.doGetAllHardware(widget.room);
    refreshIndicatorKey.currentState?.show();
    super.initState();
  }

  var db = new DatabaseHelper();

  Future getHardwareList() async {
    refreshIndicatorKey.currentState?.show();
    hwList = await _presenter.api.getAllHardware(widget.room);
    if (hwList != null) {
      setState(() {
        hwList = hwList.toList();
      });
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
    refreshIndicatorKey.currentState?.show();
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
    refreshIndicatorKey.currentState?.show();
  }

  @override
  void onSuccessRename(Hardware hw) async {
    _showSnackBar(hw.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.renameHardware(hw);
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
    _createHardware(
        String hwName, String hwSeries, String hwIP, Room room) async {
      await _presenter.doCreateHardware(hwName, hwSeries, hwIP, room);
      _hwNameController.clear();
      _hwSeriesController.clear();
      _hwIPController.clear();
    }

    _renameHardware(
        Hardware hw, String hwName, String hwSeries, String hwIP) async {
      await _presenter.doRenameHardware(hw, hwName, hwSeries, hwIP);
      _hwReNameController.clear();
      _hwReSeriesController.clear();
      _hwReIPController.clear();
    }

    Future<List> getListOfHardwareName() async {
      var db = new DatabaseHelper();
      List<Hardware> list = await db.getAllHardware();
      if (list != null) {
        List hwNameList = new List();
        for (int i = 0; i < list.length; i++) {
          hwNameList.add(list[i].hwName);
        }
        return hwNameList;
      }
      return null;
    }

    existHardwareName(String hwName) async {
      List list = await getListOfHardwareName();
      if (list == null) {
        return false;
      }
      for (int i = 0; i < list.length; i++) {
        if (hwName == list[i]) return true;
      }
      return false;
    }

    validateHardwareName(String hwName) async {
      Map validate = new Map();
      validate['error'] = true;
      validate['errorMessege'] = null;
      if (hwName.isEmpty) {
        validate['errorMessege'] = 'Please enter hardware name';
      } else if (await existHardwareName(hwName)) {
        validate['errorMessege'] = 'Hardware already exists';
      } else {
        validate['error'] = false;
        validate['errorMessege'] = null;
      }
      return validate;
    }

    _showHardwareNameDialog() async {
      _hwNameController.clear();
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
                    new TextField(
                      controller: _hwNameController,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Hardware Name',
                      ),
                    ),
                    new TextField(
                      controller: _hwSeriesController,
                      decoration: new InputDecoration(
                        labelText: 'Hardware Series',
                      ),
                    ),
                    new TextField(
                      controller: _hwIPController,
                      decoration: new InputDecoration(
                        labelText: 'Hardware IP',
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
                      Navigator.pop(context);
                      var res =
                          await validateHardwareName(_hwNameController.text);
                      if (res['error']) {
                        _showSnackBar("${res['errorMessege']}");
                      } else {
                        setState(() {
                          _isLoading = true;
                        });
                        _createHardware(
                            _hwNameController.text,
                            _hwSeriesController.text,
                            _hwIPController.text,
                            widget.room);
                      }
                    })
              ],
            ),
      );
    }

    _showHardwareReNameDialog(Hardware hw) async {
      _hwReNameController.text = hw.hwName;
      _hwReSeriesController.text = hw.hwSeries;
      _hwReIPController.text = hw.hwIP;
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
                    new TextField(
                      controller: _hwReNameController,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Hardware Name',
                      ),
                    ),
                    new TextField(
                      controller: _hwReSeriesController,
                      decoration: new InputDecoration(
                        labelText: 'Hardware Series',
                      ),
                    ),
                    new TextField(
                      controller: _hwReIPController,
                      decoration: new InputDecoration(
                        labelText: 'Hardware IP',
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
                      Navigator.pop(context);
                      var res =
                          await validateHardwareName(_hwReNameController.text);
                      if (res['error']) {
                        _showSnackBar("${res['errorMessege']}");
                      } else {
                        setState(() {
                          _isLoading = true;
                        });
                        _renameHardware(hw, _hwReNameController.text,
                            _hwReSeriesController.text, _hwReIPController.text);
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
              key: refreshIndicatorKey,
              child: createListView(context, hwList),
              onRefresh: getHardwareList,
            ),
    );
  }
}

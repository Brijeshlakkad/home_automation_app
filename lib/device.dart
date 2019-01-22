import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/logout.dart';
import 'package:home_automation/models/hardware_data.dart';
import 'package:home_automation/models/device_data.dart';
import 'package:home_automation/device/get_device_details.dart';
import 'package:home_automation/device/device_status_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/internet_access.dart';

class DeviceScreen extends StatefulWidget {
  final Home home;
  final Room room;
  final Hardware hardware;
  const DeviceScreen({this.home, this.room, this.hardware});
  @override
  DeviceScreenState createState() {
    return new DeviceScreenState();
  }
}

class DeviceScreenState extends State<DeviceScreen>
    implements DeviceScreenContract {
  final showDvScaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  var dvRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  List<Device> dvList = new List<Device>();
  List<DeviceImg> dvImgList = new List<DeviceImg>();
  bool internetAccess = false;
  void _showSnackBar(String text) {
    showDvScaffoldKey.currentState.removeCurrentSnackBar();
    showDvScaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });
    getDeviceList();
    getDeviceImgList();
    dvRefreshIndicatorKey.currentState?.show();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  var db = new DatabaseHelper();

  Future getDeviceList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      dvRefreshIndicatorKey.currentState?.show();
      dvList = await _presenter.api.getAllDevice(widget.hardware);
      if (dvList != null) {
        setState(() {
          dvList = dvList.toList();
        });
        onSuccessGetAllDevice(dvList);
      }
    } else {
      setState(() {
        dvList = new List<Device>();
        _isLoading = false;
      });
      _showSnackBar("Please check internet connection");
    }
  }

  Future getDeviceImgList() async {
    dvRefreshIndicatorKey.currentState?.show();
    dvImgList = await _presenter.api.getAllDeviceImg();
    print(dvImgList.toString());
    if (dvImgList != null) {
      setState(() {
        dvImgList = dvImgList.toList();
      });
    }
  }

  DeviceScreenPresenter _presenter;
  DeviceScreenState() {
    _presenter = new DeviceScreenPresenter(this);
  }
  @override
  void onSuccess(Device dv) async {
    _showSnackBar("Created ${dv.toString()} device");
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.saveDevice(dv);
    dvRefreshIndicatorKey.currentState?.show();
  }

  @override
  void onSuccessGetAllDevice(List<Device> dvList) async {
    if (dvList != null) {
      _showSnackBar("Got ${dvList.length}");
      setState(() => _isLoading = false);
      var db = new DatabaseHelper();
      await db.saveAllDevice(dvList);
    }
  }

  @override
  void onSuccessDelete(Device dv) async {
    _showSnackBar(dv.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.deleteDevice(dv);
    dvRefreshIndicatorKey.currentState?.show();
  }

  @override
  void onSuccessRename(Device dv) async {
    _showSnackBar(dv.toString());
    setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    await db.renameDevice(dv);
    dvRefreshIndicatorKey.currentState?.show();
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

  String getDeviceCategory(String key) {
    var value;
    for (int i = 0; i < dvImgList.length; i++) {
      DeviceImg dvImg = dvImgList[i];
      if (key == dvImg.key) {
        value = dvImg.value;
      }
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    _createDevice(
        String dvName, String dvPort, String dvImg, Hardware hw) async {
      await _presenter.doCreateDevice(dvName, dvPort, dvImg, hw);
    }

    _renameDevice(Device dv, String dvName, String dvPort, String dvImg) async {
      await _presenter.doRenameDevice(dv, dvName, dvPort, dvImg);
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

    _deleteDevice(Device dv) async {
      await _showConfirmDialog();
      if (status) {
        setState(() {
          _isLoading = true;
        });
        await _presenter.doDeleteDevice(dv);
      }
    }

    Widget createListView(BuildContext context, List<Device> dvList) {
      var len = 0;
      if (dvList != null) {
        len = dvList.length;
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
                  Map dvDetails = new Map();
                  dvDetails['isModifying'] = false;
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GetDeviceDetails(
                            hardware: widget.hardware,
                            deviceList: dvList,
                            dvDetails: dvDetails,
                            imgList: dvImgList,
                          ),
                    ),
                  );
                  print(result.toString());
                  if (result != null && !result['error']) {
                    setState(() {
                      _isLoading = true;
                    });
                    _createDevice(result['dvName'], result['dvPort'],
                        result['dvImg'], widget.hardware);
                  }
                },
                color: kHAutoBlue300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.add),
                    Text('Add Device'),
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
                    builder: (context) =>
                        DeviceStatusScreen(device: dvList[index]),
                  ),
                );
              },
              splashColor: kHAutoBlue300,
              child: Card(
                child: Container(
                  padding: EdgeInsets.only(
                      left: 10.0, top: 20.0, bottom: 20.0, right: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: ListTile(
                          title: Hero(
                            tag: dvList[index].dvName,
                            child: SizedBox(
                              width: 100.0,
                              child: Text(
                                '${dvList[index].dvName}',
                                textAlign: TextAlign.left,
                                style: Theme.of(context).textTheme.headline,
                              ),
                            ),
                          ),
                          subtitle:
                              Text("${getDeviceCategory(dvList[index].dvImg)}"),
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
                                Map dvDetails = new Map();
                                dvDetails = dvList[index].toMap();
                                dvDetails['isModifying'] = true;
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GetDeviceDetails(
                                          hardware: widget.hardware,
                                          deviceList: dvList,
                                          dvDetails: dvDetails,
                                          imgList: dvImgList,
                                        ),
                                  ),
                                );
                                print(result.toString());
                                if (result != null && !result['error']) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  _renameDevice(dvList[index], result['dvName'],
                                      result['dvImg'], result['dvPort']);
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
                                await _deleteDevice(dvList[index]);
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

    return Scaffold(
      key: showDvScaffoldKey,
      appBar: _isIOS(context)
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Hardware',
                      style: Theme.of(context).textTheme.headline,
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                    new Hero(
                      tag: widget.hardware.id,
                      child: SizedBox(
                        width: 100.0,
                        child: Text(
                          "${widget.hardware.hwName}",
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
                      'Hardware',
                      style: Theme.of(context).textTheme.headline,
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                    new Hero(
                      tag: widget.hardware.hwName,
                      child: SizedBox(
                        width: 100.0,
                        child: Text(
                          "${widget.hardware.hwName}",
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
          : RefreshIndicator(
              key: dvRefreshIndicatorKey,
              child: createListView(context, dvList),
              onRefresh: getDeviceList,
            ),
    );
  }
}

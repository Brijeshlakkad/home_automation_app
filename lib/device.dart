import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/login_signup/logout.dart';
import 'package:home_automation/models/hardware_data.dart';
import 'package:home_automation/models/device_data.dart';
import 'package:home_automation/device/get_device_details.dart';
import 'package:home_automation/device/device_status_screen.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/delete_confirmation.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:home_automation/utils/show_internet_status.dart';

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
  bool _isLoading = true;
  bool internetAccess = false;
  ShowDialog _showDialog;
  CheckPlatform _checkPlatform;
  DeleteConfirmation _deleteConfirmation;
  ShowInternetStatus _showInternetStatus;

  List<Device> dvList = new List<Device>();
  List<DeviceImg> dvImgList = new List<DeviceImg>();

  final showDvScaffoldKey = new GlobalKey<ScaffoldState>();
  var dvRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  void _showSnackBar(String text) {
    showDvScaffoldKey.currentState.removeCurrentSnackBar();
    showDvScaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  DeviceScreenPresenter _presenter;
  DeviceScreenState() {
    _presenter = new DeviceScreenPresenter(this);
  }

  @override
  void initState() {
    _showDialog = new ShowDialog();
    _deleteConfirmation = new DeleteConfirmation();
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    getDeviceList();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getDeviceList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      dvList = await _presenter.api.getAllDevice(widget.hardware);
      if (dvList != null) {
        dvList = dvList.toList();
      } else {
        dvList = new List<Device>();
      }
      getDeviceImgList();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future getDeviceImgList() async {
    dvImgList = await _presenter.api.getAllDeviceImg();
    if (dvImgList != null) {
      setState(() {
        dvImgList = dvImgList.toList();
      });
    } else {
      dvImgList = new List<DeviceImg>();
    }
  }

  @override
  void onSuccess(Device dv) async {
    _showSnackBar("Created ${dv.toString()} device");
    setState(() => _isLoading = false);
    getDeviceList();
  }

  @override
  void onSuccessDelete(Device dv) async {
    _showSnackBar(dv.toString());
    setState(() => _isLoading = false);
    getDeviceList();
  }

  @override
  void onSuccessRename(Device dv) async {
    _showSnackBar(dv.toString());
    setState(() => _isLoading = false);
    getDeviceList();
  }

  @override
  void onError(String errorTxt) {
    setState(() => _isLoading = false);
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

    _deleteDevice(Device dv) async {
      await getInternetAccessObject();
      if (internetAccess) {
        bool status = await _deleteConfirmation.showConfirmDialog(
            context, _checkPlatform.isIOS());
        if (status) {
          setState(() {
            _isLoading = true;
          });
          await _presenter.doDeleteDevice(dv);
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

    Widget _getDeviceObject(List<Device> dvList, int index, int len) {
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
                Text('Add Device'),
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
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DeviceStatusScreen(device: dvList[index]),
                ),
              );
              getDeviceList();
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
                    child: ListTile(
                      title: Hero(
                        tag: dvList[index].dvName,
                        child: Text(
                          '${dvList[index].dvName}',
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.headline,
                        ),
                      ),
                      subtitle:
                          Text("${getDeviceCategory(dvList[index].dvImg)}"),
                      trailing: new Container(
                        width: 10.0,
                        height: 10.0,
                        decoration: new BoxDecoration(
                          shape: BoxShape.circle,
                          color: dvList[index].dvStatus == 1
                              ? Colors.green
                              : Colors.red,
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
          return _getDeviceObject(dvList, index, len);
        }),
      );
    }

    Widget createListViewIOS(BuildContext context, List<Device> dvList) {
      var len = 0;
      if (dvList != null) {
        len = dvList.length;
      }
      return new SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 1.0,
          crossAxisCount: 2,
        ),
        delegate: new SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return _getDeviceObject(dvList, index, len);
          },
          childCount: len + 1,
        ),
      );
    }

    return Scaffold(
      key: showDvScaffoldKey,
      appBar: _checkPlatform.isIOS()
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
          : internetAccess
              ? _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getDeviceList),
                        new SliverSafeArea(
                          top: false,
                          sliver: createListViewIOS(context, dvList),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      key: dvRefreshIndicatorKey,
                      child: createListView(context, dvList),
                      onRefresh: getDeviceList,
                    )
              : _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getDeviceList),
                        new SliverSafeArea(
                          top: false,
                          sliver: _showInternetStatus.showInternetStatus(
                            _checkPlatform.isIOS(),
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      key: dvRefreshIndicatorKey,
                      child: _showInternetStatus.showInternetStatus(
                        _checkPlatform.isIOS(),
                      ),
                      onRefresh: getDeviceList,
                    ),
    );
  }
}

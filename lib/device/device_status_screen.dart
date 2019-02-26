import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/login_signup/logout.dart';
import 'package:home_automation/models/device_data.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:home_automation/utils/show_internet_status.dart';

class DeviceStatusScreen extends StatefulWidget {
  final Device device;
  const DeviceStatusScreen({this.device});
  @override
  DeviceStatusScreenState createState() {
    return new DeviceStatusScreenState();
  }
}

class DeviceStatusScreenState extends State<DeviceStatusScreen>
    implements DeviceStatusScreenContract {
  bool _isLoading = true;
  bool _isLoadingValue = false;
  bool internetAccess = false;
  ShowDialog _showDialog;
  CheckPlatform _checkPlatform;
  ShowInternetStatus _showInternetStatus;

  Device device;
  double vSlide = 0.0;
  var showDvStatusScaffoldKey = new GlobalKey<ScaffoldState>();
  var dvStatusRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  DeviceStatusScreenPresenter _presenter;
  DeviceStatusScreenState() {
    _presenter = new DeviceStatusScreenPresenter(this);
  }

  @override
  initState() {
    _showDialog = new ShowDialog();
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    getDeviceStatus();
    super.initState();
  }

  @override
  onSuccess(Device dv) {
    if (dv != null) {
      setState(() {
        device = dv;
      });
    } else {
      setState(() {
        device = widget.device;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void onError(String errorTxt) {
    setState(() => _isLoading = false);
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getDeviceStatus() async {
    await getInternetAccessObject();
    if (internetAccess) {
      Device device = await _presenter.api.getDevice(widget.device);
      if (device != null) {
        this.device = device;
        if (device.deviceSlider != null) {
          this.vSlide = device.deviceSlider.value.toDouble();
        } else {
          vSlide = 0.0;
        }
      } else {
        device = widget.device;
        if (widget.device.deviceSlider != null) {
          vSlide = widget.device.deviceSlider.value.toDouble();
        } else {
          vSlide = 0.0;
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget build(BuildContext context) {
    Widget showDeviceSlider(BuildContext context, Device device) {
      return device.dvImg == "ac.png"
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Text("$vSlide"),
                ),
                Container(
                  child: Slider(
                    value: vSlide,
                    min: 0.0,
                    max: 5.0,
                    divisions: 5,
                    onChanged: (val) async {
                      await getInternetAccessObject();
                      if (internetAccess) {
                        setState(() {
                          vSlide = val;
                          _isLoadingValue = true;
                        });
                        await _presenter.api.changeDeviceSlider(
                            device.deviceSlider, val.toInt());
                        setState(() {
                          _isLoadingValue = false;
                        });
                      } else {
                        this._showDialog.showDialogCustom(
                            context,
                            "Internet Connection Problem",
                            "Please check your internet connection",
                            fontSize: 17.0,
                            boxHeight: 58.0);
                      }
                    },
                  ),
                )
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Text("$vSlide"),
                ),
                Container(
                  child: Slider(
                    value: vSlide,
                    min: 0.0,
                    max: 5.0,
                    divisions: 5,
                    onChanged: (val) async {
                      await getInternetAccessObject();
                      if (internetAccess) {
                        setState(() {
                          vSlide = val;
                          _isLoadingValue = true;
                        });
                        await _presenter.api.changeDeviceSlider(
                            device.deviceSlider, val.toInt());
                        setState(() {
                          _isLoadingValue = false;
                        });
                      } else {
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
              ],
            );
    }

    Widget createDeviceView(BuildContext context, Device device) {
      return Container(
        padding: EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0),
        child: ListView(
          children: <Widget>[
            Container(
              child: Center(
                child: device.dvStatus == 1
                    ? RaisedButton(
                        color: kHAutoBlue300,
                        onPressed: () async {
                          await getInternetAccessObject();
                          if (internetAccess) {
                            setState(() {
                              _isLoading = true;
                            });
                            _presenter.doChangeDeviceStatus(device, 0);
                          }
                        },
                        child: Text("ON"),
                      )
                    : RaisedButton(
                        onPressed: () async {
                          await getInternetAccessObject();
                          if (internetAccess) {
                            setState(() {
                              _isLoading = true;
                            });
                            _presenter.doChangeDeviceStatus(device, 1);
                          }
                        },
                        child: Text("OFF"),
                      ),
              ),
            ),
            device.dvStatus == 1 && device.deviceSlider != null
                ? Container(
                    child: showDeviceSlider(context, device),
                  )
                : Container(),
            Container(
              padding: EdgeInsets.only(top: 50.0),
              child: _isLoadingValue ? ShowProgress() : null,
            )
          ],
        ),
      );
    }

    Widget showIOSDeviceSlider(BuildContext context, Device device) {
      return device.dvImg == "ac.png"
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Text("$vSlide"),
                ),
                Container(
                  child: CupertinoSlider(
                    value: vSlide,
                    min: 0.0,
                    max: 30.0,
                    divisions: 30,
                    onChanged: (val) async {
                      await getInternetAccessObject();
                      if (internetAccess) {
                        setState(() {
                          vSlide = val;
                          _isLoadingValue = true;
                        });
                        await _presenter.api.changeDeviceSlider(
                            device.deviceSlider, val.toInt());
                        setState(() {
                          _isLoadingValue = false;
                        });
                      } else {
                        this._showDialog.showDialogCustom(
                            context,
                            "Internet Connection Problem",
                            "Please check your internet connection",
                            fontSize: 17.0,
                            boxHeight: 58.0);
                      }
                    },
                  ),
                )
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Text("$vSlide"),
                ),
                Container(
                  child: CupertinoSlider(
                    value: vSlide,
                    min: 0.0,
                    max: 5.0,
                    divisions: 5,
                    onChanged: (val) async {
                      await getInternetAccessObject();
                      if (internetAccess) {
                        setState(() {
                          vSlide = val;
                          _isLoadingValue = true;
                        });
                        await _presenter.api.changeDeviceSlider(
                            device.deviceSlider, val.toInt());
                        setState(() {
                          _isLoadingValue = false;
                        });
                      } else {
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
              ],
            );
    }

    Widget createIOSDeviceView(BuildContext context, Device device) {
      List<Widget> list = [
        MergeSemantics(
          child: ListTile(
            title: Text('${device.dvName}'),
            trailing: CupertinoSwitch(
              value: device.dvStatus == 1 ? true : false,
              onChanged: (bool value) async {
                await getInternetAccessObject();
                if (internetAccess) {
                  setState(() {
                    _isLoading = true;
                  });
                  device.dvStatus == 1
                      ? _presenter.doChangeDeviceStatus(device, 0)
                      : _presenter.doChangeDeviceStatus(device, 1);
                }
              },
            ),
            onTap: () async {
              await getInternetAccessObject();
              if (internetAccess) {
                setState(() {
                  setState(() {
                    _isLoading = true;
                  });
                  device.dvStatus == 1
                      ? _presenter.doChangeDeviceStatus(device, 0)
                      : _presenter.doChangeDeviceStatus(device, 1);
                });
              }
            },
          ),
        ),
        device.dvStatus == 1 && device.deviceSlider != null
            ? Container(
                child: showIOSDeviceSlider(context, device),
              )
            : Container(),
        Container(
          padding: EdgeInsets.only(top: 50.0),
          child: _isLoadingValue ? ShowProgress() : null,
        )
      ];
      return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          return Container(
            padding: EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0),
            child: list[index],
          );
        }, childCount: list.length),
      );
    }

    String getName() {
      if (device != null) {
        return device.dvName;
      }
      return widget.device.dvName;
    }

    return Scaffold(
      key: showDvStatusScaffoldKey,
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Device',
                      style: Theme.of(context).textTheme.headline,
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                    new Hero(
                      tag: widget.device.dvName,
                      child: SizedBox(
                        width: 100.0,
                        child: Text(
                          "${getName()}",
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
              leading: new IconButton(
                tooltip: "back",
                icon: Icon(
                  Icons.arrow_back,
                  color: kHAutoBlue900,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Center(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Device',
                      style: Theme.of(context).textTheme.headline,
                    ),
                    SizedBox(
                      width: 15.0,
                    ),
                    new Hero(
                      tag: widget.device.id,
                      child: SizedBox(
                        width: 100.0,
                        child: Text(
                          "${getName()}",
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
                            onRefresh: getDeviceStatus),
                        new SliverSafeArea(
                            top: false,
                            sliver: createIOSDeviceView(context, device)),
                      ],
                    )
                  : RefreshIndicator(
                      key: dvStatusRefreshIndicatorKey,
                      child: createDeviceView(context, device),
                      onRefresh: getDeviceStatus,
                    )
              : _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getDeviceStatus),
                        new SliverSafeArea(
                          top: false,
                          sliver: _showInternetStatus.showInternetStatus(
                            _checkPlatform.isIOS(),
                          ),
                        )
                      ],
                    )
                  : RefreshIndicator(
                      key: dvStatusRefreshIndicatorKey,
                      child: _showInternetStatus.showInternetStatus(
                        _checkPlatform.isIOS(),
                      ),
                      onRefresh: getDeviceStatus,
                    ),
    );
  }
}

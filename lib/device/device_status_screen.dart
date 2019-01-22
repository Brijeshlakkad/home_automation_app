import 'package:flutter/material.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/logout.dart';
import 'package:home_automation/models/device_data.dart';
import 'package:flutter/cupertino.dart';

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
  var showDvStatusScaffoldKey = new GlobalKey<ScaffoldState>();
  var dvStatusRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  bool _isLoading = false;
  bool _isLoadingValue = false;
  Device device;
  double vSlide = 0.0;
  DeviceStatusScreenPresenter _presenter;
  @override
  initState() {
    setState(() {
      _isLoading = true;
    });
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
    print("x");
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  bool _isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS ? true : false;
  }

  void _showSnackBar(String text) {
    showDvStatusScaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  DeviceStatusScreenState() {
    _presenter = new DeviceStatusScreenPresenter(this);
  }

  Future getDeviceStatus() async {
    Device device2 = await _presenter.api.getDevice(widget.device);
    if (device2 != null) {
      setState(() {
        device = device2;
      });
      if (device2.deviceSlider != null) {
        setState(() {
          vSlide = device2.deviceSlider.value.toDouble();
        });
      }
    } else {
      setState(() {
        device = widget.device;
        vSlide = widget.device.deviceSlider.value.toDouble();
      });
      if (widget.device.deviceSlider != null) {
        setState(() {
          vSlide = widget.device.deviceSlider.value.toDouble();
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget build(BuildContext context) {
    Widget showDeviceSlider(BuildContext context, Device device) {
      return Container(
        child: Slider(
          value: vSlide,
          min: 0.0,
          max: 5.0,
          divisions: 5,
          onChanged: (val) async {
            setState(() {
              vSlide = val;
              _isLoadingValue = true;
            });
            await _presenter.api
                .changeDeviceSlider(device.deviceSlider, val.toInt());
            setState(() {
              _isLoadingValue = false;
            });
          },
        ),
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
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                          });
                          _presenter.doChangeDeviceStatus(device, 0);
                        },
                        child: Text("ON"),
                      )
                    : RaisedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                          });
                          _presenter.doChangeDeviceStatus(device, 1);
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
      return Container(
        child: CupertinoSlider(
          value: vSlide,
          min: 0.0,
          max: 5.0,
          divisions: 5,
          onChanged: (val) async {
            setState(() {
              vSlide = val;
              _isLoadingValue = true;
            });
            await _presenter.api
                .changeDeviceSlider(device.deviceSlider, val.toInt());
            setState(() {
              _isLoadingValue = false;
            });
          },
        ),
      );
    }

    Widget createIOSDeviceView(BuildContext context, Device device) {
      return Container(
        padding: EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0),
        child: ListView(
          children: <Widget>[
            MergeSemantics(
              child: ListTile(
                title: Text('${device.dvName}'),
                trailing: CupertinoSwitch(
                  value: device.dvStatus == 1 ? true : false,
                  onChanged: (bool value) {
                    setState(() {
                      _isLoading = true;
                    });
                    device.dvStatus == 1
                        ? _presenter.doChangeDeviceStatus(device, 0)
                        : _presenter.doChangeDeviceStatus(device, 1);
                  },
                ),
                onTap: () {
                  setState(() {
                    setState(() {
                      _isLoading = true;
                    });
                    device.dvStatus == 1
                        ? _presenter.doChangeDeviceStatus(device, 0)
                        : _presenter.doChangeDeviceStatus(device, 1);
                  });
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
          ],
        ),
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
      appBar: _isIOS(context)
          ? CupertinoNavigationBar(
              padding: EdgeInsetsDirectional.only(start: 0.0, top: 0.0),
              leading: Material(
                color: kHAutoBlue100,
                child: new IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: kHAutoBlue900,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
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
          : RefreshIndicator(
              key: dvStatusRefreshIndicatorKey,
              child: _isIOS(context)
                  ? createIOSDeviceView(context, device)
                  : createDeviceView(context, device),
              onRefresh: getDeviceStatus,
            ),
    );
  }
}

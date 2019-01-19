import 'package:flutter/material.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/show_progress.dart';
import 'package:home_automation/logout.dart';
import 'package:home_automation/models/device_data.dart';

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
  Device device;
  DeviceStatusScreenPresenter _presenter;
  @override
  initState() {
    setState(() {
      _isLoading=true;
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
    } else {
      setState(() {
        device = widget.device;
      });
    }
    setState(() {
      _isLoading=false;
    });
  }

  Widget build(BuildContext context) {
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
            )
          ],
        ),
      );
    }

    return Scaffold(
      key: showDvStatusScaffoldKey,
      appBar: AppBar(
        title: Text('${widget.device.dvName} Device Status'),
        actions: <Widget>[
          GetLogOut(),
        ],
      ),
      body: _isLoading
          ? ShowProgress()
          : RefreshIndicator(
              key: dvStatusRefreshIndicatorKey,
              child: createDeviceView(context, device),
              onRefresh: getDeviceStatus,
            ),
    );
  }
}

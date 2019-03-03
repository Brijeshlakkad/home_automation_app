import 'package:flutter/material.dart';
import 'package:home_automation/models/device_data.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/custom_services.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';

class GetDeviceDetails extends StatefulWidget {
  final hardware;
  final List<Device> deviceList;
  final Map dvDetails;
  final List<DeviceImg> imgList;
  GetDeviceDetails(
      {this.hardware, this.deviceList, this.dvDetails, this.imgList});
  @override
  GetDeviceDetailsState createState() {
    return new GetDeviceDetailsState();
  }
}

class GetDeviceDetailsState extends State<GetDeviceDetails> {
  bool internetAccess = false;
  ShowDialog _showDialog;
  CustomService _customService;
  CheckPlatform _checkPlatform;

  String _dvName, _dvPort, _dvImg;
  bool _isError = false;
  String _showError;
  Map deviceDetails = new Map();
  List<Device> dvList = new List<Device>();
  var dvFormKey = new GlobalKey<FormState>();
  var dvReFormKey = new GlobalKey<FormState>();
  bool _autoValidateDv = false;
  bool _autoValidateDvRe = false;

  List<String> portList = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0'
  ];

  @override
  void initState() {
    _checkPlatform = new CheckPlatform(context: context);
    _customService = new CustomService();
    _showDialog = new ShowDialog();
    if (widget.dvDetails['isModifying']) {
      setState(() {
        _dvName = widget.dvDetails['dvName'];
        _dvPort = widget.dvDetails['dvPort'];
        _dvImg = widget.dvDetails['dvImg'];
      });
    } else {
      _dvPort = portList[0];
      _dvImg = widget.imgList[0].key;
    }
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  List getListOfDeviceName() {
    List<Device> list = widget.deviceList;
    if (list != null) {
      List dvNameList = new List();
      for (int i = 0; i < list.length; i++) {
        dvNameList.add(list[i].dvName);
      }
      return dvNameList;
    }
    return null;
  }

  existDeviceName(String dvName) {
    List list = getListOfDeviceName();
    if (list == null) {
      return false;
    }
    for (int i = 0; i < list.length; i++) {
      if (dvName == list[i]) return true;
    }
    return false;
  }

  deviceNameValidator(String val, String ignoreName) {
    RegExp dvNamePattern = new RegExp(r"^(([A-Za-z]+)([1-9]*))$");
    if (val.isEmpty) {
      return 'Please enter device name';
    } else if (!dvNamePattern.hasMatch(val) ||
        val.length < 2 ||
        val.length > 8) {
      return "Device Name invalid.";
    } else if (existDeviceName(val.toLowerCase()) && val != ignoreName) {
      return '"${_customService.ucFirst(val)}" Device already exists.';
    } else {
      return null;
    }
  }

  Map portValidate(String port, String dvPort) {
    Map portV = new Map();
    for (int i = 0; i < widget.deviceList.length; i++) {
      if (widget.deviceList[i].dvPort == port.toString() && port != dvPort) {
        portV['portValid'] = false;
        portV['errorMessage'] =
            "\"${widget.deviceList[i].dvName}\" device has been assigned ${widget.deviceList[i].dvPort} port.";
        return portV;
      }
    }
    portV['portValid'] = true;
    return portV;
  }

  @override
  Widget build(BuildContext context) {
    Widget createDevice() {
      return new Center(
        child: Container(
          padding: EdgeInsets.only(top: 40.0),
          width: 300.0,
          child: new ListView(
            children: <Widget>[
              Form(
                key: dvFormKey,
                autovalidate: _autoValidateDv,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new TextFormField(
                      validator: (val) => deviceNameValidator(val, null),
                      onSaved: (val) => _dvName = val,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      decoration: new InputDecoration(
                        labelText: 'Device Name',
                      ),
                    ),
                    new InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Choose a device',
                      ),
                      child: DropdownButtonHideUnderline(
                        child: new DropdownButton<String>(
                          value: _dvImg,
                          items: widget.imgList.map((DeviceImg deviceImg) {
                            return new DropdownMenuItem<String>(
                              value: deviceImg.key,
                              child: new Text(deviceImg.value),
                            );
                          }).toList(),
                          onChanged: (String val) {
                            setState(() {
                              _dvImg = val;
                            });
                          },
                        ),
                      ),
                    ),
                    new InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Device Port',
                      ),
                      child: DropdownButtonHideUnderline(
                        child: new DropdownButton<String>(
                          value: _dvPort,
                          items: portList.map((String value) {
                            return new DropdownMenuItem<String>(
                              value: value,
                              child: new Text(value),
                            );
                          }).toList(),
                          onChanged: (String val) {
                            setState(() {
                              _dvPort = val;
                            });
                          },
                        ),
                      ),
                    ),
                    _isError
                        ? Container(
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 4.0,
                                ),
                                Text(
                                  "$_showError",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    Container(
                      padding: EdgeInsets.only(top: 30.0),
                      child: Row(
                        children: <Widget>[
                          new FlatButton(
                            child: const Text(
                              'CANCEL',
                              textScaleFactor: 1.0,
                            ),
                            onPressed: () {
                              deviceDetails['error'] = true;
                              Navigator.pop(context, deviceDetails);
                            },
                          ),
                          new FlatButton(
                            child: const Text(
                              'OK',
                              textScaleFactor: 1.0,
                              style: TextStyle(color: Colors.blue),
                            ),
                            onPressed: () async {
                              await getInternetAccessObject();
                              if (internetAccess) {
                                var form = dvFormKey.currentState;
                                if (form.validate()) {
                                  form.save();
                                  Map portV = portValidate(_dvPort, null);
                                  if (portV['portValid']) {
                                    setState(() {
                                      _autoValidateDv = false;
                                    });
                                    deviceDetails['error'] = false;
                                    deviceDetails['dvName'] = _dvName;
                                    deviceDetails['dvPort'] = _dvPort;
                                    deviceDetails['dvImg'] = _dvImg;
                                    Navigator.pop(context, deviceDetails);
                                  } else {
                                    setState(() {
                                      _isError = true;
                                      _showError = portV['errorMessage'];
                                    });
                                  }
                                } else {
                                  setState(() {
                                    _autoValidateDv = true;
                                  });
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget modifyDevice() {
      return new Center(
        child: Container(
          padding: EdgeInsets.only(top: 40.0),
          width: 300.0,
          child: new ListView(
            children: <Widget>[
              Form(
                key: dvFormKey,
                autovalidate: _autoValidateDvRe,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new TextFormField(
                      validator: (val) => deviceNameValidator(val, _dvName),
                      onSaved: (val) => _dvName = val,
                      autofocus: true,
                      initialValue: _dvName,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      decoration: new InputDecoration(
                        labelText: 'Device Name',
                      ),
                    ),
                    new InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Choose a device',
                      ),
                      child: DropdownButtonHideUnderline(
                        child: new DropdownButton<String>(
                          value: _dvImg,
                          items: widget.imgList.map((DeviceImg deviceImg) {
                            return new DropdownMenuItem<String>(
                              value: deviceImg.key,
                              child: new Text(deviceImg.value),
                            );
                          }).toList(),
                          onChanged: (String val) {
                            setState(() {
                              _dvImg = val;
                            });
                          },
                        ),
                      ),
                    ),
                    new InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Device Port',
                      ),
                      child: DropdownButtonHideUnderline(
                        child: new DropdownButton<String>(
                          value: _dvPort,
                          items: portList.map((String value) {
                            return new DropdownMenuItem<String>(
                              value: value,
                              child: new Text(value),
                            );
                          }).toList(),
                          onChanged: (String val) {
                            setState(() {
                              _dvPort = val;
                            });
                          },
                        ),
                      ),
                    ),
                    _isError
                        ? Container(
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 4.0,
                                ),
                                Text(
                                  "$_showError",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    Container(
                      padding: EdgeInsets.only(top: 30.0),
                      child: Row(
                        children: <Widget>[
                          new FlatButton(
                            child: const Text(
                              'CANCEL',
                              textScaleFactor: 1.0,
                            ),
                            onPressed: () {
                              deviceDetails['error'] = true;
                              Navigator.pop(context, deviceDetails);
                            },
                          ),
                          new FlatButton(
                            child: const Text(
                              'OK',
                              textScaleFactor: 1.0,
                              style: TextStyle(color: Colors.blue),
                            ),
                            onPressed: () async {
                              await getInternetAccessObject();
                              if (internetAccess) {
                                var form = dvFormKey.currentState;
                                if (form.validate()) {
                                  form.save();
                                  if (_dvName != widget.dvDetails['dvName'] ||
                                      _dvPort != widget.dvDetails['dvPort'] ||
                                      _dvImg != widget.dvDetails['dvImg']) {
                                    Map portV = portValidate(
                                        _dvPort, widget.dvDetails['dvPort']);
                                    if (portV['portValid']) {
                                      setState(() {
                                        _autoValidateDvRe = false;
                                      });
                                      deviceDetails['error'] = false;
                                      deviceDetails['dvName'] = _dvName;
                                      deviceDetails['dvPort'] = _dvPort;
                                      deviceDetails['dvImg'] = _dvImg;
                                      Navigator.pop(context, deviceDetails);
                                    } else {
                                      setState(() {
                                        _isError = true;
                                        _showError = portV['errorMessage'];
                                      });
                                    }
                                  } else {
                                    deviceDetails['error'] = true;
                                    Navigator.pop(context, deviceDetails);
                                  }
                                } else {
                                  setState(() {
                                    _autoValidateDvRe = true;
                                  });
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: Text(
                'Hardware Details',
                style: Theme.of(context)
                    .textTheme
                    .headline
                    .copyWith(fontSize: 18.0),
              ),
            )
          : AppBar(
              title: Center(
                child: Text(
                  'Hardware Details',
                  style: Theme.of(context)
                      .textTheme
                      .headline
                      .copyWith(fontSize: 18.0),
                ),
              ),
            ),
      body: widget.dvDetails['isModifying'] ? modifyDevice() : createDevice(),
    );
  }
}

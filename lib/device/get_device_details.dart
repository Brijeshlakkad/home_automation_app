import 'package:flutter/material.dart';
import 'package:home_automation/models/device_data.dart';

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
  var dvFormKey = new GlobalKey<FormState>();
  var dvReFormKey = new GlobalKey<FormState>();
  bool _autoValidateDv = false;
  bool _autoValidateDvRe = false;
  Map deviceDetails = new Map();
  List<Device> dvList = new List<Device>();
  String _dvName, _dvPort, _dvImg;
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
  void initState(){
    if(widget.dvDetails['isModifying']){
      setState(() {
        _dvName = widget.dvDetails['dvName'];
        _dvPort = widget.dvDetails['dvPort'];
        _dvImg = widget.dvDetails['dvImg'];
      });
    }else{
      _dvPort = portList[0];
      _dvImg = widget.imgList[0].key;
    }
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
    if (val.isEmpty) {
      return 'Please enter device name';
    } else if (existDeviceName(val) && val != ignoreName) {
      return 'Device already exists';
    } else {
      return null;
    }
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
                            onPressed: () {
                              var form = dvFormKey.currentState;
                              if (form.validate()) {
                                form.save();
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
                                  _autoValidateDv = true;
                                });
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
                            print(val);
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
                            onPressed: () {
                              var form = dvFormKey.currentState;
                              if (form.validate()) {
                                form.save();
                                if (_dvName != widget.dvDetails['dvName'] ||
                                    _dvPort != widget.dvDetails['dvPort'] ||
                                    _dvImg != widget.dvDetails['dvImg']) {
                                  setState(() {
                                    _autoValidateDvRe = false;
                                  });
                                  deviceDetails['error'] = false;
                                  deviceDetails['dvName'] = _dvName;
                                  deviceDetails['dvPort'] = _dvPort;
                                  deviceDetails['dvImg'] = _dvImg;
                                  Navigator.pop(context, deviceDetails);
                                } else {
                                  deviceDetails['error'] = true;
                                  Navigator.pop(context, deviceDetails);
                                }
                              } else {
                                setState(() {
                                  _autoValidateDvRe = true;
                                });
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
      appBar: AppBar(
        title: Text('Add Device Details'),
      ),
      body: widget.dvDetails['isModifying'] ? modifyDevice() : createDevice(),
    );
  }
}

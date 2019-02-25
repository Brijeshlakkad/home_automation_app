import 'package:flutter/material.dart';
import 'package:home_automation/models/hardware_data.dart';
import 'package:home_automation/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';

class GetHardwareDetails extends StatefulWidget {
  final room;
  final List<Hardware> hwList;
  final Map hwDetails;
  GetHardwareDetails({this.room, this.hwList, this.hwDetails});
  @override
  GetHardwareDetailsState createState() {
    return new GetHardwareDetailsState();
  }
}

class GetHardwareDetailsState extends State<GetHardwareDetails> {
  var hwFormKey = new GlobalKey<FormState>();
  var dvReFormKey = new GlobalKey<FormState>();
  bool _autoValidateDv = false;
  bool _autoValidateDvRe = false;
  bool internetAccess = false;
  ShowDialog _showDialog;
  Map hwDetails = new Map();
  String _hwName, _hwSeries, _hwIP;
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
    _showDialog = new ShowDialog();
    if (widget.hwDetails['isModifying']) {
      setState(() {
        _hwName = widget.hwDetails['hwName'];
        _hwSeries = widget.hwDetails['hwSeries'];
        _hwIP = widget.hwDetails['hwIP'];
      });
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

  List getListOfHardwareName() {
    List<Hardware> list = widget.hwList;
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
                key: hwFormKey,
                autovalidate: _autoValidateDv,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new TextFormField(
                      validator: (val) => hardwareNameValidator(val, null),
                      onSaved: (val) => _hwName = val,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Hardware Name',
                      ),
                    ),
                    new TextFormField(
                      validator: (val) => hardwareSeriesValidator(val),
                      onSaved: (val) => _hwSeries = val,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Hardware Series',
                      ),
                    ),
                    new TextFormField(
                      validator: (val) => hardwareIPValidator(val),
                      onSaved: (val) => _hwIP = val,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Hardware IP',
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
                              hwDetails['error'] = true;
                              Navigator.pop(context, hwDetails);
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
                                var form = hwFormKey.currentState;
                                if (form.validate()) {
                                  form.save();
                                  setState(() {
                                    _autoValidateDv = false;
                                  });
                                  hwDetails['error'] = false;
                                  hwDetails['hwName'] = _hwName;
                                  hwDetails['hwSeries'] = _hwSeries;
                                  hwDetails['hwIP'] = _hwIP;
                                  Navigator.pop(context, hwDetails);
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
                key: hwFormKey,
                autovalidate: _autoValidateDvRe,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new TextFormField(
                      validator: (val) => hardwareNameValidator(val, _hwName),
                      onSaved: (val) => _hwName = val,
                      autofocus: true,
                      initialValue: _hwName,
                      decoration: new InputDecoration(
                        labelText: 'Hardware Name',
                      ),
                    ),
                    new TextFormField(
                      validator: (val) => hardwareSeriesValidator(val),
                      onSaved: (val) => _hwSeries = val,
                      initialValue: _hwSeries,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Hardware Series',
                      ),
                    ),
                    new TextFormField(
                      validator: (val) => hardwareIPValidator(val),
                      onSaved: (val) => _hwIP = val,
                      autofocus: true,
                      initialValue: _hwIP,
                      decoration: new InputDecoration(
                        labelText: 'Hardware IP',
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
                              hwDetails['error'] = true;
                              Navigator.pop(context, hwDetails);
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
                                var form = hwFormKey.currentState;
                                if (form.validate()) {
                                  form.save();
                                  if (_hwName != widget.hwDetails['hwName'] ||
                                      _hwSeries !=
                                          widget.hwDetails['hwSeries'] ||
                                      _hwIP != widget.hwDetails['hwIP']) {
                                    setState(() {
                                      _autoValidateDv = false;
                                    });
                                    hwDetails['error'] = false;
                                    hwDetails['hwName'] = _hwName;
                                    hwDetails['hwSeries'] = _hwSeries;
                                    hwDetails['hwIP'] = _hwIP;
                                    Navigator.pop(context, hwDetails);
                                  } else {
                                    hwDetails['error'] = true;
                                    Navigator.pop(context, hwDetails);
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
      appBar: AppBar(
        title: Text('Add Device Details'),
      ),
      body: widget.hwDetails['isModifying'] ? modifyDevice() : createDevice(),
    );
  }
}

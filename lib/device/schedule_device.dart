import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/device_data.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:material_switch/material_switch.dart';
import 'package:home_automation/models/schedule_device_data.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/models/room_data.dart';

class ScheduleDevice extends StatefulWidget {
  final User user;
  final Room room;
  final Device device;
  final updateDeviceList;
  const ScheduleDevice(
      {this.user, this.room, this.device, this.updateDeviceList});
  @override
  ScheduleDeviceState createState() {
    return new ScheduleDeviceState(user, room, device);
  }
}

class ScheduleDeviceState extends State<ScheduleDevice>
    implements ScheduleContract {
  bool _isLoading = true;
  bool _isLoadingValue = false;
  bool internetAccess = false;
  ShowDialog _showDialog;
  CheckPlatform _checkPlatform;
  ShowInternetStatus _showInternetStatus;

  User user;
  Room room;
  Device device;
  DateTime startTime;
  DateTime endTime;
  DateTime todayDate = DateTime.now();
  String _repetition;
  List<String> repetitionList;
  bool isSwitched = true;
  var showDvStatusScaffoldKey = new GlobalKey<ScaffoldState>();
  var dvStatusRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  ScheduleDeviceState(User user, Room room, Device device) {
    this.user = user;
    this.room = room;
    this.device = device;
  }

  List<String> switchOptions;
  String selectedSwitchOption;

  Schedule schedule;
  SchedulePresenter _schedulePresenter;

  @override
  initState() {
    _showDialog = new ShowDialog();
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    repetitionList = [
      "WEEKLY",
      "ONCE",
      "MONDAY",
      "TUESDAY",
      "WEDNESDAY",
      "THURSDAY",
      "FRIDAY",
      "SATURDAY",
      "SUNDAY"
    ];
    _repetition = repetitionList[0];
    switchOptions = ["OFF", "ON"];
    selectedSwitchOption = this.switchOptions[1];
    _schedulePresenter = new SchedulePresenter(this);
    super.initState();
  }

  @override
  void onScheduleSuccess(String message) {
    _showDialog.showDialogCustom(context, "Success", message);
  }

  @override
  void onScheduleError(String errorString) {
    _showDialog.showDialogCustom(context, "Error", errorString);
  }

  String getDateTimeFormat(date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future _scheduleDevice() async {
    String afterStatus;
    await getInternetAccessObject();
    if (internetAccess) {
      if (startTime != null &&
          endTime != null &&
          selectedSwitchOption != null &&
          _repetition != null) {
        setState(() {
          _isLoading = true;
        });
        if (selectedSwitchOption == switchOptions[1]) {
          afterStatus = "1";
        } else {
          afterStatus = "0";
        }
        await _schedulePresenter.doSetSchedule(
            user,
            room,
            device,
            this.startTime.toLocal().toString(),
            this.endTime.toLocal().toString(),
            this._repetition,
            afterStatus);
      } else {
        _showDialog.showDialogCustom(
            context, "Error", "Please fill valid information!");
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget _showBody(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
      child: ListView(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              startTime == null
                  ? Text("Please select start time")
                  : Text("${getDateTimeFormat(startTime)}"),
              RaisedButton(
                onPressed: () {
                  DatePicker.showDateTimePicker(
                    context,
                    showTitleActions: true,
                    onChanged: (date) {
                      if (date.millisecondsSinceEpoch >
                          todayDate.millisecondsSinceEpoch) {
                      } else {
                        setState(() {
                          startTime = null;
                        });
                        _showDialog.showDialogCustom(
                            context, "Error", "Please select valid date");
                      }
                    },
                    onConfirm: (date) {
                      if (date.millisecondsSinceEpoch >
                          todayDate.millisecondsSinceEpoch) {
                        if (date != null && date != startTime) {
                          setState(() {
                            startTime = date;
                          });
                        }
                      } else {
                        setState(() {
                          startTime = null;
                        });
                        _showDialog.showDialogCustom(
                            context, "Error", "Please select valid date");
                      }
                    },
                    currentTime: DateTime.now(),
                    locale: LocaleType.en,
                  );
                },
                child: Text(
                  'Select Start Time',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              endTime == null
                  ? Text("Please select end time")
                  : Text("${getDateTimeFormat(endTime)}"),
              RaisedButton(
                onPressed: () {
                  DatePicker.showDateTimePicker(
                    context,
                    showTitleActions: true,
                    onChanged: (date) {
                      if (date.millisecondsSinceEpoch >
                          todayDate.millisecondsSinceEpoch) {
                      } else {
                        setState(() {
                          endTime = null;
                        });
                        _showDialog.showDialogCustom(
                            context, "Error", "Please select valid date");
                      }
                    },
                    onConfirm: (date) {
                      if (date.millisecondsSinceEpoch >
                              todayDate.millisecondsSinceEpoch &&
                          startTime != null &&
                          startTime.millisecondsSinceEpoch <
                              date.millisecondsSinceEpoch) {
                        if (date != null && date != endTime) {
                          setState(() {
                            endTime = date;
                          });
                        }
                      } else {
                        setState(() {
                          endTime = null;
                        });
                        _showDialog.showDialogCustom(
                            context, "Error", "Please select valid date");
                      }
                    },
                    currentTime: DateTime.now(),
                    locale: LocaleType.en,
                  );
                },
                child: Text(
                  'Select End Time',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10.0,
          ),
          MaterialSwitch(
            padding: const EdgeInsets.all(5.0),
            margin: const EdgeInsets.all(5.0),
            options: switchOptions,
            selectedBackgroundColor:
                this.selectedSwitchOption == this.switchOptions[0]
                    ? Colors.red
                    : Colors.green,
            selectedTextColor: Colors.white,
            onSelect: (int val) {
              setState(() {
                this.selectedSwitchOption = this.switchOptions[val];
              });
            },
          ),
          SizedBox(
            height: 10.0,
          ),
          Container(
            child: new InputDecorator(
              decoration: InputDecoration(
                labelText: 'Repetition',
              ),
              child: DropdownButtonHideUnderline(
                child: new DropdownButton<String>(
                  value: _repetition,
                  items: repetitionList.map((String value) {
                    return new DropdownMenuItem<String>(
                      value: value,
                      child: new Text("$value"),
                    );
                  }).toList(),
                  onChanged: (String val) {
                    setState(() {
                      _repetition = val;
                    });
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            height: 10.0,
          ),
          Container(
            child: RaisedButton(
              onPressed: () async {
                await _scheduleDevice();
              },
              child: Text("Schedule"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showBody(context);
  }
}

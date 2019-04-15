import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  const ScheduleDevice({this.user, this.room, this.device});
  @override
  ScheduleDeviceState createState() {
    return new ScheduleDeviceState(user, room, device);
  }
}

class ScheduleDeviceState extends State<ScheduleDevice>
    implements ScheduleContract {
  bool _isLoading = false;
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
      "DAILY",
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
    selectedSwitchOption = this.switchOptions[0];
    _schedulePresenter = new SchedulePresenter(this);
    super.initState();
  }

  @override
  void onScheduleSuccess(String message) {
    _showDialog.showDialogCustom(context, "Success", message);
    setState(() {
      this.selectedSwitchOption = this.switchOptions[0];
      _isLoading = false;
    });
  }

  @override
  void onScheduleError(String errorString) {
    _showDialog.showDialogCustom(context, "Error", errorString);
    setState(() {
      this.selectedSwitchOption = this.switchOptions[0];
      _isLoading = false;
    });
  }

  String getDateTimeFormat(date) {
    int hour = int.parse(date.hour.toString());
    String meridiem = "AM";
    if (hour > 12) {
      hour = hour - 12;
      meridiem = "PM";
    }
//    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    return "${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')} $meridiem";
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
    } else {
      _showDialog.showDialogCustom(
        context,
        "Internet Connection Error",
        "Please check your internet connection.",
        boxHeight: 57.0,
      );
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
                  DatePicker.showTimePicker(
                    context,
                    showTitleActions: true,
                    onConfirm: (date) {
                      if (date != null && date != startTime) {
                        setState(() {
                          startTime = date;
                        });
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
                  DatePicker.showTimePicker(
                    context,
                    showTitleActions: true,
                    onConfirm: (date) {
                      if (date != null && date != endTime) {
                        setState(() {
                          endTime = date;
                        });
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
                setState(() {
                  _isLoading = true;
                });
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
    return _isLoading ? ShowProgress() : _showBody(context);
  }
}

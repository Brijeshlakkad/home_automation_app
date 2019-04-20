import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/device_data.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/models/schedule_device_data.dart';
import 'package:home_automation/models/room_data.dart';
import 'package:home_automation/utils/delete_confirmation.dart';
import 'dart:async';

class ViewSchedule extends StatefulWidget {
  final User user;
  final Room room;
  final Device device;
  final updateDeviceList;
  const ViewSchedule(
      {this.user, this.room, this.device, this.updateDeviceList});
  @override
  ViewScheduleState createState() {
    return new ViewScheduleState(user, room, device);
  }
}

class ViewScheduleState extends State<ViewSchedule>
    implements ScheduleContract {
  bool _isLoading = true;
  bool _isLoadingValue = false;
  bool internetAccess = false;
  ShowDialog _showDialog;
  CheckPlatform _checkPlatform;
  ShowInternetStatus _showInternetStatus;
  DeleteConfirmation _deleteConfirmation;

  User user;
  Room room;
  Device device;
  List<Schedule> scheduleList = new List<Schedule>();
  double vSlide = 0.0;
  var showDvStatusScaffoldKey = new GlobalKey<ScaffoldState>();
  var dvStatusRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  Timer _timer;
  SchedulePresenter _schedulePresenter;
  ViewScheduleState(User user, Room room, Device device) {
    this.user = user;
    this.room = room;
    this.device = device;
  }

  @override
  initState() {
    _showDialog = new ShowDialog();
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    _schedulePresenter = new SchedulePresenter(this);
    _deleteConfirmation = new DeleteConfirmation();
    getSchedule();
    periodicCheck();
    super.initState();
  }

  void periodicCheck() async {
    await getInternetAccessObject();
    if (internetAccess) {
      _timer = new Timer.periodic(Duration(seconds: 2), (Timer t) async {
        await getSchedule();
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void onScheduleSuccess(String message) {
    setState(() => _isLoading = false);
    _showDialog.showDialogCustom(context, "Success", message);
  }

  @override
  void onScheduleError(String errorString) {
    setState(() => _isLoading = false);
    _showDialog.showDialogCustom(context, "Error", errorString);
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getSchedule() async {
    await getInternetAccessObject();
    if (internetAccess) {
      List<Schedule> scheduleList = await _schedulePresenter.api
          .getSchedule(this.user, this.device.dvName, this.room.roomName);
      if (scheduleList.length > 0) {
        this.scheduleList = scheduleList;
      } else {
        this.scheduleList = new List<Schedule>();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget build(BuildContext context) {
    Widget getScheduleObject(List<Schedule> scheduleList, int index) {
      return ListTile(
        onTap: () async {
          bool perm = await _deleteConfirmation.showConfirmDialog(
              context, _checkPlatform.isIOS(),
              title: "Do you want to remove this schedule from list");
          if (perm) {
            setState(() {
              _isLoading = true;
            });
            await _schedulePresenter.doRemoveSchedule(
                user, scheduleList[index]);
            await getSchedule();
          }
        },
        title: Text(
          "${scheduleList[index].repetition}",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Start Time: ",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  "${scheduleList[index].startTIme}",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  "End Time: ",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  "${scheduleList[index].endTime}",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Created Date: ",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  "${scheduleList[index].createdDate}",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: scheduleList[index].afterStatus == "1"
            ? Container(
                color: Colors.green,
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "ON",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            : Container(
                color: Colors.red,
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "OFF",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
      );
    }

    Widget createDeviceView(BuildContext context, List<Schedule> scheduleList) {
      int len = scheduleList.length;
      return ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          if (len == 0) {
            return Center(
              child: Container(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Device has not been scheduled.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (index == 0) {
            return Container(
              child: Container(
                padding: EdgeInsets.all(20.0),
                child: RaisedButton(
                  onPressed: () async {
                    bool perm = await _deleteConfirmation.showConfirmDialog(
                        context, _checkPlatform.isIOS(),
                        title:
                            "Do you want to remove all the scheduling for ${this.device.dvName}");
                    if (perm) {
                      setState(() {
                        _isLoading = true;
                      });
                      await _schedulePresenter.doRemoveScheduleForDevice(
                          this.user, this.device, this.room);
                      await getSchedule();
                    }
                  },
                  color: Colors.red[300],
                  child: Text(
                    "Remove All",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              padding: EdgeInsets.only(top: 10.0),
            );
          }
          return getScheduleObject(scheduleList, index - 1);
        },
        itemCount: len + 1,
      );
    }

    Widget createIOSDeviceView(
        BuildContext context, List<Schedule> scheduleList) {
      int len = scheduleList.length;
      return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          if (len == 0) {
            return Center(
              child: Container(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "Device has not been scheduled.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (index == 0) {
            return Container(
              child: Container(
                padding: EdgeInsets.all(20.0),
                child: RaisedButton(
                  onPressed: () async {
                    bool perm = await _deleteConfirmation.showConfirmDialog(
                        context, _checkPlatform.isIOS(),
                        title:
                            "Do you want to remove all the scheduling for ${this.device.dvName}");
                    if (perm) {
                      setState(() {
                        _isLoading = true;
                      });
                      await _schedulePresenter.doRemoveScheduleForDevice(
                          this.user, this.device, this.room);
                      await getSchedule();
                    }
                  },
                  color: Colors.red[300],
                  child: Text(
                    "Remove All",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              padding: EdgeInsets.only(top: 10.0),
            );
          }
          return getScheduleObject(scheduleList, index - 1);
        }, childCount: len + 1),
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
                      'Schedule',
                      style: Theme.of(context)
                          .textTheme
                          .headline
                          .copyWith(fontSize: 18.0),
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
                          style: Theme.of(context)
                              .textTheme
                              .headline
                              .copyWith(fontSize: 18.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                      'Schedule',
                      style: Theme.of(context)
                          .textTheme
                          .headline
                          .copyWith(fontSize: 17.0),
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
                          style: Theme.of(context)
                              .textTheme
                              .headline
                              .copyWith(fontSize: 17.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: _isLoading
          ? ShowProgress()
          : internetAccess
              ? _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getSchedule),
                        new SliverSafeArea(
                            top: false,
                            sliver: createIOSDeviceView(context, scheduleList)),
                      ],
                    )
                  : RefreshIndicator(
                      key: dvStatusRefreshIndicatorKey,
                      child: createDeviceView(context, scheduleList),
                      onRefresh: getSchedule,
                    )
              : _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getSchedule),
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
                      onRefresh: getSchedule,
                    ),
    );
  }
}

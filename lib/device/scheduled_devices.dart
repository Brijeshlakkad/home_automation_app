import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:flutter/services.dart';
import 'package:home_automation/models/schedule_device_data.dart';
import 'package:home_automation/utils/delete_confirmation.dart';

class ScheduledDevice extends StatefulWidget {
  final User user;
  ScheduledDevice({this.user});
  @override
  _ScheduledDeviceState createState() => _ScheduledDeviceState(user);
}

class _ScheduledDeviceState extends State<ScheduledDevice>
    implements ScheduleContract {
  bool _isLoading = true;
  bool internetAccess = false;
  CheckPlatform _checkPlatform;

  User user;
  DeleteConfirmation _deleteConfirmation;
  List<Schedule> scheduleList = new List<Schedule>();
  ShowDialog _showDialog;
  ShowInternetStatus _showInternetStatus;

  var scaffoldKey = new GlobalKey<ScaffoldState>();
  var scheduledDeviecRefreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  SchedulePresenter _schedulePresenter;

  _ScheduledDeviceState(User user) {
    this.user = user;
  }

  @override
  initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _checkPlatform = new CheckPlatform(context: context);
    _deleteConfirmation = new DeleteConfirmation();
    _showInternetStatus = new ShowInternetStatus();
    _showDialog = new ShowDialog();
    _schedulePresenter = new SchedulePresenter(this);
    getScheduleList();
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

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getScheduleList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      List<Schedule> scheduleList =
          await _schedulePresenter.api.getScheduleList(user);
      if (scheduleList != null) {
        this.scheduleList = scheduleList;
      } else {
        this.scheduleList = null;
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future removeScheduleProcess(int index) async {
    bool perm = await _deleteConfirmation.showConfirmDialog(
        context, _checkPlatform.isIOS(),
        title: "Do you want to remove this schedule from list");
    if (perm) {
      setState(() {
        _isLoading = true;
      });
      await _schedulePresenter.doRemoveSchedule(user, scheduleList[index]);
      await getScheduleList();
    }
  }

  TextStyle _subTitleStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
    fontSize: 13.0,
  );
  TextStyle _subTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 13.0,
  );
  @override
  Widget build(BuildContext context) {
    Widget getObject(List<Schedule> scheduleList, int index, int len) {
      return Card(
        elevation: 5.0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: kHAutoBlue300, width: 2.0),
          ),
          child: Container(
            margin: EdgeInsets.all(10.0),
            child: ListTile(
              onLongPress: () async {
                await removeScheduleProcess(index);
              },
              onTap: () async {
                await removeScheduleProcess(index);
              },
              title: Text(
                  "${scheduleList[index].deviceName} (${scheduleList[index].roomName})"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Start Time: ",
                        style: _subTitleStyle,
                      ),
                      Text(
                        "${scheduleList[index].startTIme}",
                        style: _subTextStyle,
                        softWrap: true,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "End Time: ",
                        style: _subTitleStyle,
                      ),
                      Text(
                        "${scheduleList[index].endTime}",
                        style: _subTextStyle,
                        softWrap: true,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Repetition: ",
                        style: _subTitleStyle,
                      ),
                      Text(
                        "${scheduleList[index].repetition}",
                        style: _subTextStyle,
                        softWrap: true,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Created Date: ",
                        style: _subTitleStyle,
                      ),
                      Text(
                        "${scheduleList[index].createdDate}",
                        style: _subTextStyle,
                        softWrap: true,
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
            ),
          ),
        ),
      );
    }

    Widget createView(BuildContext context, List<Schedule> scheduleList) {
      var len = 0;
      if (scheduleList != null) {
        len = scheduleList.length;
      }
      return new ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          if (len == 0) {
            return Container(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "Devices are not scheduled yet!",
                textAlign: TextAlign.center,
              ),
            );
          }
          if (index == 0) {
            return Container(
              padding: EdgeInsets.only(top: 10.0),
            );
          }
          return getObject(scheduleList, index - 1, len);
        },
        itemCount: len + 1,
      );
    }

    Widget createIOSView(BuildContext context, List<Schedule> scheduleList) {
      var len = 0;
      if (scheduleList != null) {
        len = scheduleList.length;
      }
      return new SliverList(
        delegate: new SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (len == 0) {
              return Container(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "Devices are not scheduled yet!",
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (index == 0) {
              return Container(
                padding: EdgeInsets.only(top: 10.0),
              );
            }
            return getObject(scheduleList, index - 1, len);
          },
          childCount: len + 1,
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: new Text("Scheduled Devices"),
            )
          : new AppBar(
              title: new Text("Scheduled Devices"),
            ),
      body: _isLoading
          ? ShowProgress()
          : internetAccess
              ? _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getScheduleList),
                        new SliverSafeArea(
                            top: false,
                            sliver: createIOSView(context, scheduleList)),
                      ],
                    )
                  : RefreshIndicator(
                      key: scheduledDeviecRefreshIndicatorKey,
                      child: createView(context, scheduleList),
                      onRefresh: getScheduleList,
                    )
              : _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getScheduleList),
                        new SliverSafeArea(
                          top: false,
                          sliver: _showInternetStatus.showInternetStatus(
                            _checkPlatform.isIOS(),
                          ),
                        )
                      ],
                    )
                  : RefreshIndicator(
                      key: scheduledDeviecRefreshIndicatorKey,
                      child: _showInternetStatus.showInternetStatus(
                        _checkPlatform.isIOS(),
                      ),
                      onRefresh: getScheduleList,
                    ),
    );
  }
}

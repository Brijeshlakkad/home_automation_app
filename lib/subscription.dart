import 'package:flutter/material.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:home_automation/models/subscription_data.dart';

class SubscriptionScreen extends StatefulWidget {
  final User user;
  SubscriptionScreen({this.user});
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState(user);
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    implements SubscriptionContract {
  bool _isLoading = true;
  bool internetAccess = false;
  CheckPlatform _checkPlatform;

  User user;
  ShowDialog showDialog;
  ShowInternetStatus _showInternetStatus;

  var scaffoldKey = new GlobalKey<ScaffoldState>();
  var subscriptionRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  List<Subscription> subscriptionList = new List();
  SubscriptionPresenter _subscriptionPresenter;

  _SubscriptionScreenState(User user) {
    this.user = user;
  }

  @override
  initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    _subscriptionPresenter = new SubscriptionPresenter(this);
    getSubscriptionList();
    showDialog = new ShowDialog();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getSubscriptionList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      subscriptionList =
          await _subscriptionPresenter.api.getSubscription(this.user);
    }
    setState(() => _isLoading = false);
  }

  @override
  void onError(String errorString) {
    setState(() {
      _isLoading = false;
    });
    this.showDialog.showDialogCustom(context, "Error", errorString);
  }

  @override
  Widget build(BuildContext context) {
    Widget drawBox(Subscription subscription) {
      return Container(
        padding: EdgeInsets.all(10.0),
        decoration:
            BoxDecoration(border: Border.all(color: kHAutoBlue300, width: 1.0)),
        child: Column(
          children: [
            Row(
              children: <Widget>[
                Text("Hardware Series"),
                Expanded(
                  child: Container(),
                ),
                Text("${subscription.hwSeries}"),
              ],
            ),
            Row(
              children: <Widget>[
                Text("Expiration Date"),
                Expanded(
                  child: Container(),
                ),
                Text("${subscription.leftTime}"),
              ],
            ),
            Row(
              children: <Widget>[
                Text("State"),
                Expanded(
                  child: Container(),
                ),
                subscription.state == "Running"
                    ? Text(
                        "${subscription.state}",
                        style: TextStyle(color: Colors.green),
                      )
                    : Text(
                        "${subscription.state}",
                        style: TextStyle(color: Colors.red),
                      ),
              ],
            ),
          ],
        ),
      );
    }

    Widget _getSubscriptionObject(
        List<Subscription> subscriptionList, int index, int len) {
      return Container(
        padding: EdgeInsets.all(10.0),
        child: drawBox(subscriptionList[index]),
      );
    }

    Widget createListViewIOS(
        BuildContext context, List<Subscription> subscriptionList) {
      var len = 0;
      if (subscriptionList != null) {
        len = subscriptionList.length;
      }
      return new SliverList(
        delegate: new SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (len == 0) {
              return Container(
                padding: EdgeInsets.only(top: 10.0),
                child: Text(
                  "You have not started using any hardwares.",
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (index == 0) {
              return Container(
                padding: EdgeInsets.only(top: 10.0),
              );
            }
            return _getSubscriptionObject(subscriptionList, index - 1, len);
          },
          childCount: len + 1,
        ),
      );
    }

    Widget createListView(BuildContext context, List<Subscription> memberList) {
      var len = 0;
      if (memberList != null) {
        len = memberList.length;
      }
      return new ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          if (len == 0) {
            return Container(
              padding: EdgeInsets.only(top: 10.0),
              child: Text(
                "You have not started using any hardwares.",
                textAlign: TextAlign.center,
              ),
            );
          }
          if (index == 0) {
            return Container(
              padding: EdgeInsets.only(top: 10.0),
            );
          }
          return _getSubscriptionObject(memberList, index - 1, len);
        },
        itemCount: len + 1,
      );
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text("Subscription"),
      ),
      body: _isLoading
          ? ShowProgress()
          : internetAccess
              ? _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getSubscriptionList),
                        new SliverSafeArea(
                          top: false,
                          sliver: createListViewIOS(context, subscriptionList),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      key: subscriptionRefreshIndicatorKey,
                      child: createListView(context, subscriptionList),
                      onRefresh: getSubscriptionList,
                    )
              : _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getSubscriptionList),
                        new SliverSafeArea(
                            top: false,
                            sliver: _showInternetStatus
                                .showInternetStatus(_checkPlatform.isIOS())),
                      ],
                    )
                  : RefreshIndicator(
                      key: subscriptionRefreshIndicatorKey,
                      child: _showInternetStatus
                          .showInternetStatus(_checkPlatform.isIOS()),
                      onRefresh: getSubscriptionList,
                    ),
    );
  }
}

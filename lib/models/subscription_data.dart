import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/utils/custom_exception.dart';
import 'package:home_automation/models/user_data.dart';

class Subscription {
  String _hwSeries, _leftTime, _state;
  Subscription(this._leftTime, this._state);
  Subscription.map(dynamic obj) {
    this._hwSeries = obj['serialNo'];
    this._leftTime = obj['leftTime'];
    if (int.parse(obj['state'].toString()) == 1) {
      this._state = "Running";
    } else {
      this._state = "Expired";
    }
  }
  String get hwSeries => _hwSeries;
  String get leftTime => _leftTime;
  String get state => _state;
  Map<String, dynamic> toMap() {
    Map obj = new Map();
    obj['serialNo'] = this._hwSeries;
    obj['leftTime'] = this._leftTime;
    obj['state'] = this._state;
    return obj;
  }

  @override
  String toString() {
    return hwSeries;
  }
}

class RequestSubscription {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://homeautomations.tk/brijesh/server_files';
  static final finalURL = baseURL + "/customer_actions.php";

  Future<List<Subscription>> getSubscription(User user) async {
    int userID = user.id;
    return _netUtil.post(finalURL, body: {
      "action": "1",
      "userID": userID.toString(),
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      int total = int.parse(res['user']['totalRows'].toString());
      List<Subscription> subscriptionList = new List<Subscription>();
      for (int i = 0; i < total; i++) {
        subscriptionList.add(Subscription.map(res['user']['row'][i]));
      }
      return subscriptionList;
    });
  }
}

abstract class SubscriptionContract {
  void onError(String errorTxt);
}

class SubscriptionPresenter {
  SubscriptionContract _view;
  RequestSubscription api = new RequestSubscription();
  SubscriptionPresenter(this._view);
}

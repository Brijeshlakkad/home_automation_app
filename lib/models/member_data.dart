import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/utils/custom_exception.dart';
import 'package:home_automation/models/user_data.dart';
import 'dart:convert';

class Member {
  String _email, _name;
  String _hwName;
  Member(this._email, this._name, this._hwName);
  Member.map(dynamic obj) {
    this._email = obj['email'];
    this._name = obj['name'];
    this._hwName = obj['hwName'];
  }
  String get email => _email;
  String get name => _name;
  String get hwName => _hwName;
  Map<String, dynamic> toMap() {
    Map obj = new Map();
    obj['email'] = this._email;
    obj['name'] = this._name;
    obj['hwName'] = this._hwName;
    return obj;
  }

  @override
  String toString() {
    return email;
  }
}

class Hw {
  String _hwName, _hwSeries;
  Hw(this._hwName, this._hwSeries);
  Hw.map(dynamic obj) {
    this._hwName = obj['hwName'];
    this._hwSeries = obj['hwSeries'];
  }
  String get hwName=> _hwName;
  String get hwSeries => _hwSeries;
  Map<String, dynamic> toMap() {
    Map obj = new Map();
    obj['hwName'] = this._hwName;
    obj['hwSeries'] = this._hwSeries;
    return obj;
  }

  @override
  String toString() {
    return hwName;
  }
}
class RequestMember {
  NetworkUtil _netUtil = new NetworkUtil();
  static final baseURL = 'https://homeautomations.tk/brijesh/server_files';
  static final finalURL = baseURL + "/customer_actions.php";

  Future<List<Member>> getMembers(User user) async {
    int userID = user.id;
    return _netUtil.post(finalURL, body: {
      "action": "0",
      "userID": userID.toString(),
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      int total = int.parse(res['user']['memberRows'].toString());
      List<Member> memberList = new List<Member>();
      for (int i = 0; i < total; i++) {
        memberList.add(Member.map(res['user']['memberList'][i]));
      }
      return memberList;
    });
  }

  Future<String> removeMember(User user, Member member) {
    int userID = user.id;
    return _netUtil.post(finalURL, body: {
      "action": "3",
      "userID": userID.toString(),
      "memberEmail": member.email,
      "hwName": member.hwName,
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return res['responseMessage'];
    });
  }

  Future<String> saveMember(User user, String memberEmail, String hwSeries) {
    List memberModelList = new List();
    memberModelList.add(memberEmail);
    int userID = user.id;
    return _netUtil.post(finalURL, body: {
      "action": "2",
      "userID": userID.toString(),
      "memberModelList": jsonEncode(memberModelList),
      "hwSeries": hwSeries,
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      if (res['user']['failed']['error'])
        throw new FormException(res['user']['failed']['errorMessage']);
      if (res['user']['notExists']['error'])
        throw new FormException(res['user']['notExists']['errorMessage']);
      return res['responseMessage'];
    });
  }

  Future<List<Hw>> getHardwareList(User user) async {
    return _netUtil.post(finalURL, body: {
      "action": "4",
      "email": user.email.toString(),
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      int total = int.parse(res['user']['totalRows'].toString());
      List<Hw> hwList = new List<Hw>();
      for (int i = 0; i < total; i++) {
        hwList.add(Hw.map(res['user']['hwList'][i]));
      }
      return hwList;
    });
  }
}

abstract class MemberContract {
  void onSuccess(String responseMessage);
  void onError(String errorTxt);
}

class MemberPresenter {
  MemberContract _view;
  RequestMember api = new RequestMember();
  MemberPresenter(this._view);
  doRemoveMember(User user, Member member) async {
    try {
      String responseMessage = await api.removeMember(user, member);
      _view.onSuccess(responseMessage);
    } on Exception catch (error) {
      _view.onError(error.toString());
    }
  }

  doSaveMember(User user, String memberEmail, String hwSeries) async {
    try {
      String responseMessage =
          await api.saveMember(user, memberEmail, hwSeries);
      _view.onSuccess(responseMessage);
    } on Exception catch (error) {
      _view.onError(error.toString());
    }
  }
}

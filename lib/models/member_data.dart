import 'package:home_automation/utils/network_util.dart';
import 'package:home_automation/utils/custom_exception.dart';
import 'package:home_automation/models/user_data.dart';
import 'dart:convert';

class Member {
  String _email, _name;
  Member(this._email, this._name);
  Member.map(dynamic obj) {
    this._email = obj['email'];
    this._name = obj['name'];
  }
  String get email => _email;
  String get name => _name;
  Map<String, dynamic> toMap() {
    Map obj = new Map();
    obj['email'] = this._email;
    obj['name'] = this._name;
    return obj;
  }

  @override
  String toString() {
    return email;
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

  Future<String> removeMember(User user, String memberEmail) {
    int userID = user.id;
    return _netUtil.post(finalURL, body: {
      "action": "3",
      "userID": userID.toString(),
      "memberEmail": memberEmail,
    }).then((dynamic res) {
      print(res.toString());
      if (res["error"]) throw new FormException(res["errorMessage"]);
      return res['responseMessage'];
    });
  }

  Future<String> saveMember(User user, String memberEmail) {
    List memberModelList = new List();
    memberModelList.add(memberEmail);
    int userID = user.id;
    return _netUtil.post(finalURL, body: {
      "action": "2",
      "userID": userID.toString(),
      "memberModelList": jsonEncode(memberModelList),
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
}

abstract class MemberContract {
  void onSuccess(String responseMessage);
  void onError(String errorTxt);
}

class MemberPresenter {
  MemberContract _view;
  RequestMember api = new RequestMember();
  MemberPresenter(this._view);
  doRemoveMember(User user, String memberEmail) async {
    try {
      String responseMessage = await api.removeMember(user, memberEmail);
      _view.onSuccess(responseMessage);
    } on Exception catch (error) {
      _view.onError(error.toString());
    }
  }

  doSaveMember(User user, String memberEmail) async {
    try {
      String responseMessage = await api.saveMember(user, memberEmail);
      _view.onSuccess(responseMessage);
    } on Exception catch (error) {
      _view.onError(error.toString());
    }
  }
}

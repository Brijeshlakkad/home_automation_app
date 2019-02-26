import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/models/user_data.dart';

enum AuthState { LOGGED_IN, LOGGED_OUT }

abstract class AuthStateListener {
  void onAuthStateChanged(AuthState state, User user);
}

// A naive implementation of Observer/Subscriber Pattern. Will do for now.
class AuthStateProvider implements UserContract {
  bool internetAccess = false;
  UserPresenter _userPresenter;
  User user;
  static final AuthStateProvider _instance = new AuthStateProvider.internal();

  List<AuthStateListener> _subscribers;

  factory AuthStateProvider() => _instance;
  AuthStateProvider.internal() {
    _userPresenter = new UserPresenter(this);
    _subscribers = new List<AuthStateListener>();
    getInternetAccessObject();
    initState();
  }
  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    internetAccess = await checkInternetAccess.check();
  }

  void initState() async {
    var db = new DatabaseHelper();
    var isLoggedIn = await db.isLoggedIn();
    if (isLoggedIn) {
      if (internetAccess) {
        final user = await db.getUser();
        await _userPresenter.doGetUser(user);
      } else {
        final user = await db.getUserDetails();
        notify(AuthState.LOGGED_IN, user);
      }
    } else
      notify(AuthState.LOGGED_OUT, null);
  }

  void subscribe(AuthStateListener listener) {
    _subscribers.add(listener);
  }

  void dispose(AuthStateListener listener) {
    for (var l in _subscribers) {
      if (l == listener) _subscribers.remove(l);
    }
  }

  void notify(AuthState state, User user) {
    _subscribers
        .forEach((AuthStateListener s) => s.onAuthStateChanged(state, user));
  }

  @override
  void onUserError() {
    user = null;
    var db = new DatabaseHelper();
    db.deleteUsers();
    notify(AuthState.LOGGED_OUT, null);
  }

  @override
  void onUserSuccess(User userDetails) {
    user = userDetails;
    notify(AuthState.LOGGED_IN, user);
  }
}

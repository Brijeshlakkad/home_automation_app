import 'package:flutter/material.dart';
import 'package:home_automation/home.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/login_signup/login.dart';
import 'package:home_automation/login_signup/signup.dart';
import 'package:home_automation/hardware.dart';
import 'package:splashscreen/splashscreen.dart';

class HomeAutomation extends StatefulWidget {
  HomeAutomationState createState() => HomeAutomationState();
}

class HomeAutomationState extends State<HomeAutomation> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Home Automation',
      theme: _kHomeAutomationTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeAutomationSplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => HomeScreen(),
        '/hardware': (context) => HardwareScreen(),
      },
    );
  }
}

class HomeAutomationSplashScreen extends StatefulWidget {
  @override
  _HomeAutomationSplashScreenState createState() =>
      new _HomeAutomationSplashScreenState();
}

class _HomeAutomationSplashScreenState
    extends State<HomeAutomationSplashScreen> {
  @override
  Widget build(BuildContext context) {
    return new SplashScreen(
      seconds: 3,
      loadingText: Text("Please wait"),
      navigateAfterSeconds: new LoginScreen(),
      title: new Text(
        'Home Automation',
        style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 35.0),
      ),
      backgroundColor: Colors.white,
      styleTextUnderTheLoader: new TextStyle(),
      photoSize: 100.0,
      image: Image.asset("assets/images/logo.png"),
      onClick: () => print("Home Automation"),
      loaderColor: Colors.white,
    );
  }
}

final ThemeData _kHomeAutomationTheme = _buildAppTheme();

ThemeData _buildAppTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    accentColor: kHAutoBlue900,
    primaryColor: kHAutoBlue100,
    buttonColor: kHAutoBlue100,
    scaffoldBackgroundColor: kHAutoBackgroundWhite,
    cardColor: kHAutoBackgroundWhite,
    textSelectionColor: kHAutoBlue100,
    errorColor: kShrineErrorRed,
    buttonTheme: base.buttonTheme.copyWith(
      buttonColor: kHAutoBlue100,
      textTheme: ButtonTextTheme.normal,
    ),
    primaryIconTheme: base.iconTheme.copyWith(color: kHAutoBlue900),
    textTheme: _buildAppTextTheme(base.textTheme),
    primaryTextTheme: _buildAppTextTheme(base.primaryTextTheme),
    accentTextTheme: _buildAppTextTheme(base.accentTextTheme),
  );
}

TextTheme _buildAppTextTheme(TextTheme base) {
  return base
      .copyWith(
        headline: base.headline.copyWith(
          fontWeight: FontWeight.w500,
        ),
        title: base.title.copyWith(fontSize: 18.0),
        caption: base.caption.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 14.0,
        ),
        body2: base.body2.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 16.0,
        ),
      )
      .apply(
        fontFamily: 'Raleway',
        displayColor: kHAutoBlue900,
        bodyColor: kHAutoBlue900,
      );
}

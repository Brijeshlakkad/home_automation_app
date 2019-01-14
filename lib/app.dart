import 'package:flutter/material.dart';
import 'home.dart';
import 'colors.dart';
import 'login.dart';
class HomeAutomation extends StatefulWidget{
  HomeAutomationState createState() => HomeAutomationState();
}
class HomeAutomationState extends State<HomeAutomation>{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Automation',
      theme: _kHomeAutomationTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
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
    primaryIconTheme: base.iconTheme.copyWith(
        color: kHAutoBlue900
    ),
    textTheme: _buildAppTextTheme(base.textTheme),
    primaryTextTheme: _buildAppTextTheme(base.primaryTextTheme),
    accentTextTheme: _buildAppTextTheme(base.accentTextTheme),
  );
}

TextTheme _buildAppTextTheme(TextTheme base) {
  return base.copyWith(
    headline: base.headline.copyWith(
      fontWeight: FontWeight.w500,
    ),
    title: base.title.copyWith(
        fontSize: 18.0
    ),
    caption: base.caption.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 14.0,
    ),
    body2: base.body2.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 16.0,
    ),
  ).apply(
    displayColor: kHAutoBlue900,
    bodyColor: kHAutoBlue900,
  );
}
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:home_automation/utils/color_loader.dart';

class ShowProgress extends StatelessWidget {
  bool _isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
          child: ColorLoader(
        color1: Colors.redAccent,
        color2: Colors.blue[500],
        color3: Colors.green[300],
      )),
    );
  }
}

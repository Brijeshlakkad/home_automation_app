import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ShowProgress extends StatelessWidget {
  bool _isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return _isIOS(context)
        ? Container(
            child: Center(
              child: CupertinoActivityIndicator(
                radius: 15.0,
              ),
            ),
          )
        : Container(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
  }
}

import 'package:flutter/material.dart';
import 'package:home_automation/data/database_helper.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/home_data.dart';

class HomeObject extends StatefulWidget{
  final Home home;
  const HomeObject({this.home});
  @override
  HomeObjectState createState() {
    return new HomeObjectState();
  }
}

class HomeObjectState extends State<HomeObject> {
  bool _isLoading = false;
  Widget showProgress() {
    return Container(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home: ${widget.home.homeName}'),
      ),
      body: _isLoading ? showProgress() : ShowRoomsOfHome(home:widget.home),
    );
  }
}

class ShowRoomsOfHome extends StatefulWidget{
  final Home home;
  const ShowRoomsOfHome({this.home});
  @override
  ShowRoomsOfHomeState createState() {
    return new ShowRoomsOfHomeState();
  }
}

class ShowRoomsOfHomeState extends State<ShowRoomsOfHome> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
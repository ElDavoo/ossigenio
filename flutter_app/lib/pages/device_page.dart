import 'package:flutter/material.dart';

import '../../utils/device.dart';

class DevicePage extends StatefulWidget {
  final Device devic;

  const DevicePage({Key ?key, required this.devic}) : super(key: key);

  @override
  _DevicePageState createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {

  // Override back button and disconnect
  Future<bool> _onWillPop() async {
    widget.devic.bleManager.disconnect();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop
        , child:
        DefaultTabController(
          initialIndex: 0,
          length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Device'),
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(
                  text: 'Device',
                ),
                Tab(
                  text: 'Messages',
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: <Widget> [
              const Placeholder(),
              Column(
                  children: [
                    Text(widget.devic.device.toString()),
                  ]
              ),
            ],
            ))));
  }
}
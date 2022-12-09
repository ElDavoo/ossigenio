import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../utils/device.dart';

class DevicePage extends StatefulWidget {
  final Device devic;

  const DevicePage({Key ?key, required this.devic}) : super(key: key);

  @override
  _DevicePageState createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device'),
      ),
      body: Column(
        children: [
          Text(widget.devic.device.toString()),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Go back"),
          ),
        ]
      ),
    );
  }
}
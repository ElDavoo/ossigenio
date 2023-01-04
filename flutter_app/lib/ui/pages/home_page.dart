import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../managers/ble_man.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'new_home_page.dart';
import '../../Messages/co2_message.dart';
import '../../Messages/debug_message.dart';
import '../../Messages/feedback_message.dart';
import '../../Messages/message.dart';
import '../widgets/debug_tab.dart';
import '../../utils/device.dart';
import '../../utils/log.dart';
import '../widgets/device_tab.dart';
import 'login_page.dart';
import 'map_page.dart';
import 'package:new_gradient_app_bar/new_gradient_app_bar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //BLEManager bleManager = BLEManager();
  // get BLEManager from ChangeNotifierProvider

  StreamSubscription? _log;
  Device? _device;

  void _init() {
    // Read the device mac address from shared preferences
    PrefManager().read(PrefConstants.deviceMac).then((value) {
      /*if (value != null) {
        // Attempt to connect to the device
        bleManager.connectToDevice(value);
      }*/
    });
    _log = Log.addListener(context);
  }

  @override
  void initState() {
    super.initState();
    _init();
    //bleManager.startBLEScan();
  }

  int _selectedIndex = 0;

  @override
  void dispose() {
    BLEManager().stopBLEScan();
    _log?.cancel();
    super.dispose();
  }



  final List<Widget> _pages = <Widget>[
    const NewHomePage(),
    const MapPage(),
  ];
  PageController pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  void pageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void bottomTapped(int index) {
    setState(() {
      _selectedIndex = index;
      pageController.animateToPage(index,
          duration: const Duration(milliseconds: 100), curve: Curves.ease);
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: NewGradientAppBar(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.blueAccent],
          ),
          leading: IconButton(
            icon: const Icon(Icons.no_accounts),
            onPressed: () {
              // Show a dialog to confirm logout
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("AppLocalizations.of(context)!.logout"),
                      content: Text(
                          "AppLocalizations.of(context)!.logoutConfirmMessage"),
                      actions: [
                        TextButton(
                          child: Text("AppLocalizations.of(context)!.cancel"),
                          onPressed: () {
                            AccountManager().logout();
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()));
                          },
                        ),
                        TextButton(
                          child: Text("AppLocalizations.of(context)!.logout"),
                          onPressed: () {
                            // Logout
                            Navigator.of(context).pop();
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()));
                          },
                        ),
                      ],
                    );
                  });
            },
          ),
          title: Text(AppLocalizations.of(context)!.title),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: bluetoothStateWidget(),
            ),
          ]),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.fromRGBO(227, 252, 230, 0.8),
              Color.fromRGBO(111, 206, 250, 0.5)
            ],
          ),
        ),
        child: PageView.builder(
          controller: pageController,
          onPageChanged: (index) {
            pageChanged(index);
          },
          itemCount: _pages.length,
          itemBuilder: (BuildContext context, int index) {
            return _pages[index];
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 50,
        selectedFontSize: 15,
        selectedIconTheme: const IconThemeData(color: Colors.blue, size: 32),
        selectedItemColor: Colors.blue,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mappa',
            backgroundColor: Colors.green,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: bottomTapped,
      ),
    );
  }

  GestureDetector bluetoothStateWidget() {
    return GestureDetector(
      onTap: () {},
      child: const Icon(Icons.bluetooth),
    );
  }
}

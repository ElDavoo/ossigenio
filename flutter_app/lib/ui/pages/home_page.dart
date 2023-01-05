import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/Messages/startup_message.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
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
    // Add a disconnection event
    BLEManager().devicestream.stream.listen((event) {
      if (BLEManager().dvc !=  null) {
        BLEManager().dvc!.messagesStream.where((event)
        {
          if (event.direction == MessageDirection.received) {
            if (event.message is FeedbackMessage) {
              return true;
            }
          }
          return false;
        })
        .map((msg) => msg.message)
        .cast<FeedbackMessage>()
            .listen((event) {
          _showOverlay(context, fbvalue: event.feedback);
        });
        }
      }
    );
    BLEManager().disconnectstream.add(null);

    FlutterNativeSplash.remove();
  }

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    animation =
        CurveTween(curve: Curves.fastOutSlowIn).animate(animationController!);
    _init();

    //bleManager.startBLEScan();
  }

  int _selectedIndex = 0;
  AnimationController? animationController;
  Animation<double>? animation;
  @override
  void dispose() {
    BLEManager().stopBLEScan();
    _log?.cancel();
    super.dispose();
  }



  final List<Widget> _pages = <Widget>[
    NewHomePage(),
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
                              Navigator.of(context).pop();
                            }),
                        TextButton(
                          child: Text("AppLocalizations.of(context)!.logout"),
                          onPressed: () {
                            // Logout
                            AccountManager().logout().then((value) {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginPage()),
                                  (route) => false);
                            });
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
              child: bluetoothBatt(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: bluetoothRSSI(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
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
        backgroundColor: const Color.fromRGBO(255,255,255, 0.2),
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
      onTap: () {
        // Show the device tab
        if (BLEManager().dvc != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DebugTab(
                        device: BLEManager().dvc!,
                      )));
        } else {
          Log.l("Nessun dispositivo connesso");
        }
      },
      child: const Icon(Icons.bluetooth),
    );
  }
  Widget bluetoothRSSI() {
    return StreamBuilder(
        stream: BLEManager().disconnectstream.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container();
          } else {
            return StreamBuilder(
              stream: BLEManager().devicestream.stream,
              builder: (context, snapshot) {
                if (BLEManager().dvc != null) {
                  return StreamBuilder<int>(
                      stream: BLEManager.rssiStream(BLEManager().dvc!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          int rssi = snapshot.data!;
                          if (rssi > -70) {
                            return const Icon(Icons.signal_cellular_alt_sharp);
                          } else if (rssi > -90) {
                            return const Icon(
                                Icons.signal_cellular_alt_2_bar_sharp);
                          } else {
                            return const Icon(
                                Icons.signal_cellular_alt_1_bar_sharp);
                          }
                        } else {
                          return Container();
                        }
                      });
                } else {
                  return Container();
                }
              },);

          }
        });

  }

  Widget bluetoothBatt() {
    return StreamBuilder(
        stream: BLEManager().disconnectstream.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Container();
          } else {
            return StreamBuilder(
              stream: BLEManager().devicestream.stream,
              builder: (context, snapshot) {
                if (BLEManager().dvc != null) {
                  return StreamBuilder<int>(
                      stream: BLEManager().dvc!.messagesStream
                      .where((element) => element.direction == MessageDirection.received)
                          .where((element) => element.message is StartupMessage)
                          .map((event) => event.message as StartupMessage)
                          .map((event) => event.battery),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          int battery = snapshot.data!;
                          if (battery == 100) {
                            return const Icon(Icons.power);
                          } else if (battery > 88) {
                            return const Icon(Icons.battery_full);
                          } else if (battery > 76) {
                            return const Icon(Icons.battery_6_bar);
                          } else if (battery > 64) {
                            return const Icon(Icons.battery_5_bar);
                          } else if (battery > 52) {
                            return const Icon(Icons.battery_4_bar);
                          } else if (battery > 40) {
                            return const Icon(Icons.battery_3_bar);
                          } else if (battery > 28) {
                            return const Icon(Icons.battery_2_bar);
                          } else if (battery > 16) {
                            return const Icon(Icons.battery_1_bar);
                          } else {
                            return const Icon(Icons.battery_alert);
                          }

                        } else {
                          return Container();
                        }
                      });
                } else {
                  return Container();
                }
              },);

          }
        });

  }

  void _showOverlay(BuildContext context, {required FeedbackValues fbvalue}) async {
    // Convert the fbvalue to an emoji with a dict
    final Map<FeedbackValues, String> emojiDict = {
      FeedbackValues.negative: "🙁",
      FeedbackValues.neutral: "😐",
      FeedbackValues.positive: "😉",
    };
    final String emoji = emojiDict[fbvalue]!;

    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(builder: (context) {
      return               FadeTransition(
      opacity: animation!,
        child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.fromRGBO(227, 252, 230, 0.9),
              Color.fromRGBO(111, 206, 250, 0.6)
            ],
          ),
        ),
        child: Center(
          child: Material(

                child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 80),
                  ),
              ),
            ),

        ),
      );
    });
    animationController!.addListener(() {
      overlayState!.setState(() {});
    });
    // inserting overlay entry
    overlayState!.insert(overlayEntry);
    animationController!.forward();
    await Future.delayed(const Duration(seconds: 1))
        .whenComplete(() => animationController!.reverse())
    // removing overlay entry after stipulated time.
        .whenComplete(() => overlayEntry.remove());
  }

}

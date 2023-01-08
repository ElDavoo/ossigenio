import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/Messages/startup_message.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/utils/ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:new_gradient_app_bar/new_gradient_app_bar.dart';

import '../../../managers/ble_man.dart';
import '../../Messages/feedback_message.dart';
import '../../Messages/message.dart';
import '../../utils/constants.dart';
import '../../utils/log.dart';
import '../widgets/debug_tab.dart';
import 'login_page.dart';
import 'main_page.dart';
import 'map_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {

  late final StreamSubscription _log;

  void _init() {
    _log = Log.addListener(context);
    // Mostra l'overlay di feedback quando arriva il feedback
    BLEManager().devicestream.stream.listen((event) {
      if (BLEManager().dvc != null) {
        BLEManager()
            .dvc!
            .messagesStream
            .where((event) {
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
              // Manda il feedback solo se il sensore è caldo
              if (BLEManager().dvc!.isHeating) {
                Log.l(AppLocalizations.of(context)!.waitForHeating);
              } else {
              _showOverlay(context, fbvalue: event.feedback);
              // Mostra un messaggio di ringraziamento
              Future.delayed(const Duration(seconds: 2), () {
                Log.l(AppLocalizations.of(context)!.feedbackSent);
              }
              );}
            });
      }
    });
    BLEManager().disconnectstream.add(null);

    FlutterNativeSplash.remove();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    animation =
        CurveTween(curve: Curves.fastOutSlowIn).animate(_animationController!);
    _init();
  }

  int _selectedIndex = 0;
  AnimationController? _animationController;
  Animation<double>? animation;

  @override
  void dispose() {
    BLEManager().stopBLEScan();
    _log.cancel();
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
    return Scaffold(
      appBar: NewGradientAppBar(
          gradient: LinearGradient(
            colors: [C.colors.blue1, C.colors.blue2],
          ),
          leading: IconButton(
            icon: const Icon(Icons.no_accounts),
            onPressed: () {
              // Show a dialog to confirm logout
              buildLogoutDialog(context);
            },
          ),
          title: Text(AppLocalizations.of(context)!.title),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: bluetoothBatt(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: bluetoothRSSI(),
            ),
          ]),
      body: Container(
        decoration: UIWidgets.gradientBox(),
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
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }

  void buildLogoutDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.logout),
            content: Text(AppLocalizations.of(context)!.logoutConfirmMessage),
            actions: [
              TextButton(
                  child: Text(AppLocalizations.of(context)!.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
              TextButton(
                child: Text(AppLocalizations.of(context)!.logout),
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
  }

  BottomNavigationBar buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      selectedFontSize: 15,
      selectedIconTheme: const IconThemeData(color: Colors.blue, size: 32),
      selectedItemColor: Colors.blue,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      backgroundColor: C.colors.cardBg,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: AppLocalizations.of(context)!.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.map),
          label: AppLocalizations.of(context)!.map,
        ),
      ],
      currentIndex: _selectedIndex,
      onTap: bottomTapped,
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
                  return InkWell(
                    onLongPress: () {
                      if (BLEManager().dvc != null) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DebugTab(
                                      device: BLEManager().dvc!,
                                    )));
                      }
                    },
                    child: StreamBuilder<int>(
                        stream: BLEManager.rssiStream(BLEManager().dvc!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            int rssi = snapshot.data!;
                            if (rssi > -70) {
                              return const Icon(
                                  Icons.signal_cellular_alt_sharp);
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
                        }),
                  );
                } else {
                  return Container();
                }
              },
            );
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
                      stream: BLEManager()
                          .dvc!
                          .messagesStream
                          .where((element) =>
                              element.direction == MessageDirection.received)
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
              },
            );
          }
        });
  }

  void _showOverlay(BuildContext context,
      {required FeedbackValues fbvalue}) async {
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
      return FadeTransition(
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
    _animationController!.addListener(() {
      overlayState!.setState(() {});
    });
    // inserting overlay entry
    overlayState!.insert(overlayEntry);
    _animationController!.forward();
    await Future.delayed(const Duration(seconds: 1))
        .whenComplete(() => _animationController!.reverse())
        // removing overlay entry after stipulated time.
        .whenComplete(() => overlayEntry.remove());
  }
}

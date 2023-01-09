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
import '../../utils/device.dart';
import '../../utils/log.dart';
import '../tabs/home_tab.dart';
import '../tabs/map_tab.dart';
import '../widgets/debug_tab.dart';
import 'login_page.dart';

/// La UI principale dell'app, contiene la barra di navigazione e le pagine
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Lo stato della home page dell'app
class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription _log;

  void _init() {
    _log = Log.addListener(context);
    // Listen to the BLE manager dvc ValueNotifier
    // Mostra l'overlay di feedback quando arriva il feedback
    BLEManager().dvc.addListener(() {
      if (BLEManager().dvc.value != null) {
        BLEManager()
            .dvc
            .value!
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
              if (BLEManager().dvc.value!.isHeating) {
                Log.l(AppLocalizations.of(context)!.waitForHeating);
              } else {
                _showOverlay(context, fbvalue: event.feedback);
                // Mostra un messaggio di ringraziamento
                Future.delayed(const Duration(seconds: 2), () {
                  Log.l(AppLocalizations.of(context)!.feedbackSent);
                });
              }
            });
      }
    });

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

  @override
  void dispose() {
    BLEManager().stopBLEScan();
    _log.cancel();
    super.dispose();
  }

  /// La pagina corrente
  int _selectedIndex = 0;
  AnimationController? _animationController;
  Animation<double>? animation;

  /// Lista delle pagine da mostrare
  final List<Widget> _pages = <Widget>[
    const NewHomePage(),
    const MapPage(),
  ];

  final PageController _pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  /// Cambia pagina
  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 100), curve: Curves.ease);
    });
  }

  /// Costruisce la barra inferiore dell'app
  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
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
      onTap: _changePage,
    );
  }

  /// Chiede all'utente se vuole uscire dall'applicazione
  static void _buildLogoutDialog(BuildContext context) {
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

  void _showOverlay(BuildContext context,
      {required FeedbackValues fbvalue}) async {
    // Convert the fbvalue to an emoji with a dict
    // TODO usare delle foto di emoji, resa grafica migliore
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

  Widget _bluetoothRSSI() {
    return ValueListenableBuilder(
        valueListenable: BLEManager().dvc,
        builder: (context, Device? dvc, _) {
          if (dvc == null) {
            return const SizedBox();
          }
          return InkWell(
            onLongPress: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DebugTab(
                            device: dvc,
                          )));
            },
            child: StreamBuilder<int>(
                stream: BLEManager.rssiStream(dvc),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    int rssi = snapshot.data!;
                    if (rssi > -70) {
                      return const Icon(Icons.signal_cellular_alt_sharp);
                    } else if (rssi > -90) {
                      return const Icon(Icons.signal_cellular_alt_2_bar_sharp);
                    } else {
                      return const Icon(Icons.signal_cellular_alt_1_bar_sharp);
                    }
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
          );
        });
  }

  Widget _bluetoothBatt() {
    return ValueListenableBuilder(
        valueListenable: BLEManager().dvc,
        builder: (context, Device? dvc, _) {
          if (dvc == null) {
            return const SizedBox();
          }
          return StreamBuilder<int>(
              stream: dvc.messagesStream
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
                  return const CircularProgressIndicator();
                }
              });
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
            color: Colors.white,
            onPressed: () {
              // Show a dialog to confirm logout
              _buildLogoutDialog(context);
            },
          ),
          title: Text(AppLocalizations.of(context)!.title),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: _bluetoothBatt(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: _bluetoothRSSI(),
            ),
          ]),
      body: Container(
        decoration: UI.gradientBox(),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            _changePage(index);
          },
          itemCount: _pages.length,
          itemBuilder: (BuildContext context, int index) {
            return _pages[index];
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}

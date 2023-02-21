import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/Messages/startup_message.dart';
import 'package:flutter_app/utils/ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lottie/lottie.dart';
import 'package:new_gradient_app_bar/new_gradient_app_bar.dart';

import '../../../managers/ble_man.dart';
import '../../Messages/feedback_message.dart';
import '../../Messages/message.dart';
import '../../utils/constants.dart';
import '../../utils/device.dart';
import '../../utils/log.dart';
import '../tabs/home_tab.dart';
import '../widgets/debug_tab.dart';

/// La UI principale dell'app, contiene la barra di navigazione e le pagine
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Lo stato della home page dell'app
class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
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

  AnimationController? _animationController;
  Animation<double>? animation;

  void _showOverlay(BuildContext context,
      {required FeedbackValues fbvalue}) async {
    final Map<FeedbackValues, LottieBuilder> lottieDict = {
      FeedbackValues.negative:
          Lottie.asset('assets/images/negative.json', repeat: false),
      FeedbackValues.neutral:
          Lottie.asset('assets/images/neutral.json', repeat: false),
      FeedbackValues.positive:
          Lottie.asset('assets/images/positive.json', repeat: false),
    };
    final LottieBuilder lottie = lottieDict[fbvalue]!;

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
            child: SizedBox(
              width: 200,
              height: 200,
              child: lottie,
            ),
          ),
        ),
      );
    });
    _animationController!.addListener(() {
      overlayState.setState(() {});
    });
    // inserting overlay entry
    overlayState.insert(overlayEntry);
    _animationController!.forward();
    await Future.delayed(const Duration(milliseconds: 1500))
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
        child: const HomeTab(),
      ),
    );
  }
}

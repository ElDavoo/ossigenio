import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/managers/gps_man.dart';
import 'package:flutter_app/managers/mqtt_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_app/ui/pages/splash.dart';
import 'package:provider/provider.dart';
import '../managers/ble_man.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'ui/pages/home_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';


void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
        /* Start to initialize the various app subsystems
          * (e.g. BLE, DB, etc.) */
        PrefManager();
        BLEManager();
        if (kDebugMode) {
          //debugPaintSizeEnabled=true;
        }

    runApp(
        /*MultiProvider(providers: [
          ChangeNotifierProvider(create: (context) => BLEManager()),

        ],
          child: const MyApp(),
        ));*/
        const MyApp());
  });
  /*
  Bisogna mettere qui i ChangeNotifierProvider.
  In questo modo, saranno disponibili globalmente.
   */

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) =>
      AppLocalizations.of(context)!.title,
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: const SplashPage(),
    );
  }
}





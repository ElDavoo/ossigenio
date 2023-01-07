import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/managers/perm_man.dart';
import 'package:flutter_app/managers/pref_man.dart';
import 'package:flutter_app/ui/pages/login_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../managers/ble_man.dart';
import 'ui/pages/home_page.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    /* Start to initialize the various app subsystems
          * (e.g. BLE, DB, etc.) */
    PrefManager();
    BLEManager();
    PermissionManager().checkPermissions();
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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late Widget initialWidget;

  @override
  void initState() {
    super.initState();
    initialWidget = const Text("Errore");
    AccountManager().login().then((value) {
      if (value) {
        setState(() {
          initialWidget = const MyHomePage();
        });
      } else {
        setState(() {
          initialWidget = const LoginPage();
        });
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.title,
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
      ),
      home: initialWidget,
    );
  }
}

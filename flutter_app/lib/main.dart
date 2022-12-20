import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../managers/ble_man.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
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
      home: const MyHomePage(),
    );
  }
}





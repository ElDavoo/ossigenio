import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/managers/perm_man.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'ui/pages/home_page.dart';

void main() {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    // Iniziamo a inizializzare i manager
    PermissionManager().checkPermissions();
    runApp(const App(initialWidget: HomePage()));
  });
}

class App extends StatefulWidget {
  final Widget initialWidget;

  const App({Key? key, required this.initialWidget}) : super(key: key);

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.title,
      theme: ThemeData(
        // Colore principale dell'applicazione
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: widget.initialWidget,
    );
  }
}

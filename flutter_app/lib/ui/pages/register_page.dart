import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/ui/pages/home_page.dart';
import 'package:flutter_app/utils/ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/constants.dart';
import '../../utils/log.dart';

/// UI della pagina di registrazione
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

/// Stato della UI della pagina di registrazione
class _RegisterPageState extends State<RegisterPage> {
  /// Controller per il campo di testo dello username
  final usernameinputController = TextEditingController();

  /// Controller per il campo di testo dell'email
  final emailinputController = TextEditingController();

  /// Controller per il campo di testo della password
  final passwordinputController = TextEditingController();

  late final StreamSubscription? _log;

  @override
  void initState() {
    super.initState();
    _log = Log.addListener(context);
  }

  @override
  void dispose() {
    _log?.cancel();
    super.dispose();
  }

  /// Azioni alla pressione del tasto di registrazione
  void _onRegisterPressed() {
    AccountManager()
        .register(
          email: emailinputController.text,
          name: usernameinputController.text,
          password: passwordinputController.text,
        )
        .then((value) => {
              if (value)
                {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  )
                }
              else
                {
                  Log.l(AppLocalizations.of(context)!.signupFailed),
                }
            });
  }

  @override
  Widget build(BuildContext context) {
    // Register page
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
          decoration: UI.gradientBox(),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset('assets/icon/icon.png', height: 150),
                // Big text with product name
                Padding(
                  padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
                  child: FittedBox(
                    child: Text(
                      AppLocalizations.of(context)!.title,
                      style: C.stylebig,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(30, 10, 30, 0),
                  child: TextField(
                    controller: usernameinputController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      labelText: AppLocalizations.of(context)!.username,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
                  child: TextField(
                    keyboardType: TextInputType.emailAddress,
                    controller: emailinputController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      labelText: AppLocalizations.of(context)!.email,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
                  child: TextField(
                    controller: passwordinputController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      labelText: AppLocalizations.of(context)!.password,
                    ),
                  ),
                ),
                Container(
                    height: 80,
                    padding: const EdgeInsets.fromLTRB(150, 30, 150, 0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _onRegisterPressed,
                      child: Text(AppLocalizations.of(context)!.signup),
                    )),
              ],
            ),
          )),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/ui/pages/register_page.dart';
import 'package:flutter_app/utils/ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../managers/account_man.dart';
import '../../utils/log.dart';
import 'home_page.dart';

/// UI della pagina di login
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

/// Stato della UI della pagina di login
class LoginPageState extends State<LoginPage> {
  /// Controller per il campo di testo dell'email
  final emailinputController = TextEditingController();

  /// Controller per il campo di testo della password
  final passwordinputController = TextEditingController();

  /// Stream per il log
  late final StreamSubscription _log;

  @override
  void initState() {
    super.initState();
    _log = Log.addListener(context);
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _log.cancel();
    super.dispose();
  }

  /// Prova a fare il login
  void _loginButton() {
    AccountManager()
        .loginWith(emailinputController.text, passwordinputController.text)
        .then((value) => {
              if (value)
                {
                  // Se il login ha successo, vai alla home page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  )
                }
            });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
            decoration: UI.gradientBox(),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    // TODO sostituire con logo
                    child: const FlutterLogo(
                      size: 120,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: emailinputController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        labelText: AppLocalizations.of(context)!.email,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
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
                      padding: const EdgeInsets.fromLTRB(130, 30, 130, 0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: _loginButton,
                        child: Text(
                          AppLocalizations.of(context)!.login,
                        ),
                      )),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.signup,
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
            )));
  }
}

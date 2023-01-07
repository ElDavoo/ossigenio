/*
Stateful widget for register page
 */
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_app/ui/pages/home_page.dart';

import '../../utils/log.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameinputController = TextEditingController();
  final emailinputController = TextEditingController();
  final passwordinputController = TextEditingController();

  StreamSubscription? _log;

  @override
  void initState() {
    super.initState();
    _log = Log.addListener(context);
  }

  @override
  void dispose() {
    // Clean up the
    _log?.cancel();
    super.dispose();
  }

  void onPressed() {
    AccountManager()
        .register(emailinputController.text, usernameinputController.text,
            passwordinputController.text)
        .then((value) => {
              if (value)
                {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                  )
                }
              else
                {Log.l('Register failed')}
            });
  }

  @override
  Widget build(BuildContext context) {
    // Register page
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: const FlutterLogo(
                    size: 120,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: TextField(
                    controller: usernameinputController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      labelText: 'Nome utente',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: TextField(
                    controller: emailinputController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      labelText: 'Email',
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
                      labelText: 'Password',
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
                      onPressed: onPressed,
                      child: const Text('Registrati'),
                    )),
              ],
            ),
          )),
    );
  }
}

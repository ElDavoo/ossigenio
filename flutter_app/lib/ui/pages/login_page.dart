/*
A flutter login page that can also be used as a sign up page.
 */
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/ui/pages/register_page.dart';

import '../../managers/account_man.dart';
import '../../utils/log.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
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
        .loginWith(emailinputController.text, emailinputController.text)
        .then((value) => {
              if (value)
                {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                  )
                }
              else
                {Log.l('Login failed')}
            });
  }

  @override
  Widget build(BuildContext context) {
    // Login page
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                        child: const Text('Log In'),
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
                      'Registrati',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            )
        )
    );
  }
}

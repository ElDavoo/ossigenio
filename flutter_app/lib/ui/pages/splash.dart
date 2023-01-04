import 'package:flutter/material.dart';
import 'package:flutter_app/managers/account_man.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'home_page.dart';
import 'login_page.dart';

// A splash screen

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    AccountManager().login().then((value) {
      if (value) {
        FlutterNativeSplash.remove();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
      } else {
        FlutterNativeSplash.remove();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    })
    .catchError((error) {
      FlutterNativeSplash.remove();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
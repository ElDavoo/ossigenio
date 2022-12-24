/*
A flutter login page that can also be used as a sign up page.
 */
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/ui/pages/register_page.dart';

import '../../managers/account_man.dart';
import '../../utils/log.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final logininputController = TextEditingController();
  final registerinputController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    // Login page
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(children: [
          // Logo
          const SizedBox(
            height: 100,
          ),
          const Text(
            'Logo',
            style: TextStyle(fontSize: 50),
          ),
          const SizedBox(
            height: 100,
          ),
          // Email
          const Text(
            'Email',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: logininputController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Email',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          // Password
          const Text(
            'Password',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: registerinputController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          // Login button
          ElevatedButton(
            onPressed: () {
              AccountManager().loginWith(
                  logininputController.text, registerinputController.text);
            },
            child: const Text('Login'),
          ),
          // Link to register page
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
            child: const Text('Register'),
          ),
        ]));
  }
}

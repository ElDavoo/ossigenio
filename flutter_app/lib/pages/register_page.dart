/*
Stateful widget for register page
 */
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/managers/account_man.dart';

import '../utils/log.dart';

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

  @override
  Widget build(BuildContext context) {
    // Register page
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
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
            controller: emailinputController,
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
            controller: passwordinputController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          // Confirm password
          const Text(
            'Confirm password',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: usernameinputController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'username',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          // Register button
          ElevatedButton(
            onPressed: () {
              AccountManager.register(
                      emailinputController.text,
                      usernameinputController.text,
                      passwordinputController.text)
                  .then((value) => {
                        if (value)
                          {
                            //Pop navigator two times
                            Navigator.of(context).pop(),
                            Navigator.of(context).pop(),
                          }
                      });
            },
            child: null,
          ),
        ],
      ),
    );
  }
}

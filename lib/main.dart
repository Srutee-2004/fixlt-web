import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() => runApp(const FixItApp());

class FixItApp extends StatelessWidget {
  const FixItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixIt',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routes: {'/': (_) => const LoginScreen()},
    );
  }
}

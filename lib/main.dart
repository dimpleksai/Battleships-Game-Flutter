import 'package:flutter/material.dart';
import 'package:battleships/views/login.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Battleships',
    home: LoginView(),
    routes: {
      '/login': (context) => LoginView(),
    },
  ));
}

import 'package:flutter/material.dart';
import 'package:synnal/app/app_loading_screen.dart';
import 'package:synnal/features/auth/ui/screens/login_screen.dart';
import 'package:synnal/features/home/ui/screens/home_screen.dart';

Map<String, WidgetBuilder> synnalRoutes() {
  return <String, WidgetBuilder>{
    '/': (context) =>
        const AppLoadingScreen(),
    '/login': (context) =>
        const LoginScreen(),
    '/home': (context) =>
        const HomeScreen(),
  };
}
import 'package:flutter/widgets.dart';
import 'package:rana_jayeen/page/MapScreen.dart';
import 'package:rana_jayeen/page/tips.dart';

import 'package:rana_jayeen/page/navigation_home_screen.dart';
import 'package:rana_jayeen/page/home/parts/4/report.dart';

import 'page/auth.dart';
import 'page/home/home_screen.dart';

import 'page/splash_screen.dart';

final Map<String, WidgetBuilder> routes = {
  SplashScreen.routeName: (context) => const SplashScreen(),

  '/car_fixes_tips': (context) => const CarFixesTipsScreen(),
  CompleteProfileScreen.routeName: (context) => const CompleteProfileScreen(),
  HomeScreen.routeName: (context) => const HomeScreen(),
  Detailtest.routeName: (context) => Detailtest(),
  NavigationHomeScreen.routeName: (context) => NavigationHomeScreen(),
  MapScreen.routeName: (context) => MapScreen(),
  CarFixesTipsScreen.routeName: (context) => CarFixesTipsScreen()
  // Gasla.routeName: (context) => Gasla(),
};

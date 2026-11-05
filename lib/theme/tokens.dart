import 'package:flutter/material.dart';

/// Shared dimensions with live Figma palettes in HobbyTheme.
/// See docs/figma-ui-report.md for native and behavioral adaptations.
abstract final class AppColors {
  static const hobbyBlue = Color(0xFF548BBF);
  static const hobbyOrange = Color(0xFFCE8467);
  static const hobbyPurple = Color(0xFF906DB4);
  static const hobbyPink = Color(0xFFBD738C);
  static const hobbyGold = Color(0xFFAE843A);
  static const primary = Color(0xFF087F72);
  static const primaryDark = Color(0xFF076F64);
  static const text = Color(0xFF213D36);
  static const muted = Color(0xFF4F6F63);
  static const subtle = Color(0xFF526F63);
  static const background = Color(0xFFF7FAF7);
  static const surface = Color(0xFFFFFFFF);
  static const soft = Color(0xFFE7F5ED);
  static const border = Color(0xFFD8E9DF);
  static const inputBorder = Color(0xFFCBDED2);
  static const heroStart = Color(0xFFD8F3E5);
  static const heroEnd = Color(0xFFC1E8DF);
  static const error = Color(0xFFA2353E);
  static const warning = Color(0xFFAE542F);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = 20.0;
  static const card = 16.0;
  static const navGap = 8.0;
}

abstract final class AppRadii {
  static const small = 10.0;
  static const control = 12.0;
  static const card = 16.0;
  static const hero = 21.0;
  static const sheet = 24.0;
}

abstract final class AppSizes {
  static const minTap = 48.0;
  static const appBar = 70.0;
  static const navigation = 76.0;
  static const navigationIconWidth = 46.0;
  static const navigationIconHeight = 32.0;
  static const navigationIcon = 19.0;
  static const logo = 32.0;
}

abstract final class AppElevation {
  static const card = 1.0;
  static const dialog = 4.0;
}

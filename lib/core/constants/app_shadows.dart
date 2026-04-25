import 'package:flutter/material.dart';

/// Premium-feel elevation shadows. Tuned for both light and dark surfaces.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x336366F1),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}

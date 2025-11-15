import 'package:flutter/material.dart';

class KConstants {
  static const String themeModeKey = 'themeModeKey';
}

class KTextStyle {
  static const TextStyle header = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF333333),
  );

  static const TextStyle subHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF666666),
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF999999),
  );
}
//
// class KValue{
//   static const String basicLayout = 'Basic Layout';
//   static const String fixBugs = 'Fix Bugs';
//   static const cleanUi = 'Clean Ui';
//   static const String keyConcepts = 'Key Concepts';
// }
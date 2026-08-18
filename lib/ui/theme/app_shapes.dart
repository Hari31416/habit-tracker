import 'package:flutter/material.dart';

class AppShapes {
  static const double extraSmallRadius = 4.0;
  static const double smallRadius = 8.0;
  static const double mediumRadius = 14.0;
  static const double cardRadius = 16.0;
  static const double largeRadius = 20.0;
  static const double extraLargeRadius = 28.0;

  static const BorderRadius extraSmall = BorderRadius.all(Radius.circular(extraSmallRadius));
  static const BorderRadius small = BorderRadius.all(Radius.circular(smallRadius));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(mediumRadius));
  static const BorderRadius card = BorderRadius.all(Radius.circular(cardRadius));
  static const BorderRadius large = BorderRadius.all(Radius.circular(largeRadius));
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(extraLargeRadius));

  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: card,
  );
}

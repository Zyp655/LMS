import 'package:flutter/material.dart';

class AnimationConfig {
  AnimationConfig._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  static const Curve defaultCurve = Curves.easeOut;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
  static const Curve springCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;

  static const Duration staggerDelay = Duration(milliseconds: 100);
  static const Duration shortStaggerDelay = Duration(milliseconds: 50);

  static const double fadeStart = 0.0;
  static const double fadeEnd = 1.0;

  static const double scaleStart = 0.8;
  static const double scaleEnd = 1.0;
  static const double scalePressed = 0.95;

  static const Offset slideFromBottom = Offset(0, 0.5);
  static const Offset slideFromTop = Offset(0, -0.5);
  static const Offset slideFromLeft = Offset(-0.5, 0);
  static const Offset slideFromRight = Offset(0.5, 0);
}

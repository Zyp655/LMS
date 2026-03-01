import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveProgressIndicator extends StatelessWidget {
  final double width;
  final double height;

  const RiveProgressIndicator({
    super.key,
    this.width = double.infinity,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const RiveAnimation.asset(
        'lib/rive/5839-11380-linear-indeterminate-progress.riv',
        fit: BoxFit.contain,
      ),
    );
  }
}

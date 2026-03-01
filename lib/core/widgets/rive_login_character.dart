import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveLoginCharacter extends StatefulWidget {
  final double height;

  const RiveLoginCharacter({super.key, this.height = 300});

  @override
  State<RiveLoginCharacter> createState() => RiveLoginCharacterState();
}

class RiveLoginCharacterState extends State<RiveLoginCharacter> {
  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  void _onRiveInit(Artboard artboard) {
    artboard.fills.clear();

    String? stateMachineName;
    for (final animation in artboard.animations) {
      if (animation is StateMachine) {
        debugPrint(
          '[RiveLoginCharacter] Found StateMachine: "${animation.name}"',
        );
        stateMachineName ??= animation.name;
      }
    }

    if (stateMachineName == null) {
      debugPrint('[RiveLoginCharacter] No StateMachine found in artboard!');
      return;
    }

    debugPrint('[RiveLoginCharacter] Using StateMachine: "$stateMachineName"');

    final controller = StateMachineController.fromArtboard(
      artboard,
      stateMachineName,
    );

    if (controller == null) {
      debugPrint(
        '[RiveLoginCharacter] Failed to create controller for "$stateMachineName"',
      );
      return;
    }

    artboard.addController(controller);
    _controller = controller;

    for (final input in controller.inputs) {
      debugPrint(
        '[RiveLoginCharacter] Input: "${input.name}" (type: ${input.type})',
      );
    }

    _isChecking = controller.getBoolInput('Check');
    _isHandsUp = controller.getBoolInput('hands_up');
    _trigSuccess = controller.getTriggerInput('success');
    _trigFail = controller.getTriggerInput('fail');
    _numLook = controller.getNumberInput('Look');

    debugPrint(
      '[RiveLoginCharacter] isChecking: ${_isChecking != null ? "connected" : "NOT FOUND"}',
    );
    debugPrint(
      '[RiveLoginCharacter] isHandsUp: ${_isHandsUp != null ? "connected" : "NOT FOUND"}',
    );
    debugPrint(
      '[RiveLoginCharacter] trigSuccess: ${_trigSuccess != null ? "connected" : "NOT FOUND"}',
    );
    debugPrint(
      '[RiveLoginCharacter] trigFail: ${_trigFail != null ? "connected" : "NOT FOUND"}',
    );
    debugPrint(
      '[RiveLoginCharacter] numLook: ${_numLook != null ? "connected" : "NOT FOUND"}',
    );
  }

  void startChecking() {
    _isHandsUp?.value = false;
    _isChecking?.value = true;
  }

  void stopChecking() {
    _isChecking?.value = false;
  }

  void handsUp() {
    _isChecking?.value = false;
    _isHandsUp?.value = true;
  }

  void handsDown() {
    _isHandsUp?.value = false;
  }

  void success() {
    _isChecking?.value = false;
    _isHandsUp?.value = false;
    _trigSuccess?.fire();
  }

  void fail() {
    _isChecking?.value = false;
    _isHandsUp?.value = false;
    _trigFail?.fire();
  }

  void setLookDirection(double direction) {
    _numLook?.value = direction;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: RiveAnimation.asset(
        'lib/rive/3469-7899-login-screen-character.riv',
        fit: BoxFit.contain,
        onInit: _onRiveInit,
      ),
    );
  }
}

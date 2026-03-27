import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PlatformCamera {
  CameraController? _controller;
  bool _initialized = false;
  Timer? _captureTimer;

  String _lastEmotion = 'neutral';
  double _lastConfidence = 0;

  void Function(String emotion, double confidence)? onLocalDetection;

  bool get isInitialized => _initialized;
  bool get needsOpenAiConfirmation => true;
  String get lastEmotion => _lastEmotion;
  double get lastConfidence => _lastConfidence;

  void resetConfirmationFlag() {}

  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras available');

    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _controller!.initialize();
    _initialized = true;
  }

  Future<Uint8List?> captureImage() async {
    if (_controller == null || !_initialized) return null;
    final image = await _controller!.takePicture();
    return await image.readAsBytes();
  }

  Widget buildPreview() {
    if (_controller == null || !_initialized) return const SizedBox.shrink();
    return CameraPreview(_controller!);
  }

  void dispose() {
    _captureTimer?.cancel();
    _captureTimer = null;
    _controller?.dispose();
    _controller = null;
    _initialized = false;
  }
}

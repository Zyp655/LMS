import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';

class EmotionCameraWidget extends StatefulWidget {
  final void Function(String emotion, double confidence) onEmotionDetected;

  const EmotionCameraWidget({super.key, required this.onEmotionDetected});

  @override
  State<EmotionCameraWidget> createState() => _EmotionCameraWidgetState();
}

class _EmotionCameraWidgetState extends State<EmotionCameraWidget> {
  CameraController? _cameraController;
  bool _isEnabled = false;
  bool _isInitializing = false;
  bool _isAnalyzing = false;
  String _currentEmotion = 'neutral';
  Timer? _captureTimer;

  @override
  void dispose() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    setState(() => _isInitializing = true);

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      _captureTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _captureAndAnalyze(),
      );

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isEnabled = false;
        });
      }
    }
  }

  Future<void> _stopCamera() async {
    _captureTimer?.cancel();
    _captureTimer = null;
    await _cameraController?.dispose();
    _cameraController = null;
  }

  Future<void> _toggle() async {
    if (_isEnabled) {
      await _stopCamera();
      setState(() {
        _isEnabled = false;
        _currentEmotion = 'neutral';
      });
    } else {
      setState(() => _isEnabled = true);
      await _initCamera();
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isAnalyzing) return;

    _isAnalyzing = true;

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/ai/detect-emotion'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'imageBase64': base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final emotion = data['emotion'] as String? ?? 'neutral';
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0;

        if (mounted) {
          setState(() => _currentEmotion = emotion);
          widget.onEmotionDetected(emotion, confidence);
        }
      }
    } catch (_) {}

    _isAnalyzing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      right: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isEnabled ? 80 : 36,
              height: _isEnabled ? 65 : 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(_isEnabled ? 10 : 18),
                border: Border.all(
                  color: _isEnabled
                      ? _emotionColor().withValues(alpha: 0.8)
                      : Colors.white30,
                  width: 2,
                ),
              ),
              child: _isEnabled && _cameraController != null && _cameraController!.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CameraPreview(_cameraController!),
                    )
                  : _isInitializing
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.face_retouching_natural,
                          size: 18,
                          color: Colors.white54,
                        ),
            ),
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _emotionColor().withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _emotionLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _emotionColor() {
    switch (_currentEmotion) {
      case 'confused':
        return Colors.orange;
      case 'frustrated':
        return Colors.red;
      case 'bored':
        return Colors.grey;
      case 'focused':
        return AppColors.success;
      case 'happy':
        return AppColors.accent;
      default:
        return Colors.blueGrey;
    }
  }

  String _emotionLabel() {
    switch (_currentEmotion) {
      case 'confused':
        return '🤔 Bối rối';
      case 'frustrated':
        return '😤 Khó chịu';
      case 'bored':
        return '😴 Chán';
      case 'focused':
        return '🎯 Tập trung';
      case 'happy':
        return '😊 Vui';
      default:
        return '😐 Bình thường';
    }
  }
}

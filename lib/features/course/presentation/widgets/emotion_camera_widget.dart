import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import 'emotion_camera_web.dart' if (dart.library.io) 'emotion_camera_native.dart';

class EmotionCameraWidget extends StatefulWidget {
  final void Function(String emotion, double confidence) onEmotionDetected;

  const EmotionCameraWidget({super.key, required this.onEmotionDetected});

  @override
  State<EmotionCameraWidget> createState() => _EmotionCameraWidgetState();
}

class _EmotionCameraWidgetState extends State<EmotionCameraWidget> {
  bool _isEnabled = false;
  bool _isInitializing = false;
  String _currentEmotion = 'neutral';
  PlatformCamera? _platformCamera;
  Timer? _confirmTimer;

  @override
  void dispose() {
    _confirmTimer?.cancel();
    _platformCamera?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    setState(() => _isInitializing = true);

    try {
      _platformCamera = PlatformCamera();

      _platformCamera!.onLocalDetection = (emotion, confidence) {
        if (mounted) {
          setState(() => _currentEmotion = emotion);
          widget.onEmotionDetected(emotion, confidence);
        }
      };

      await _platformCamera!.initialize();

      _confirmTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkAndConfirm(),
      );

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint('[EmotionCamera] Init error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isEnabled = false;
        });
      }
    }
  }

  Future<void> _checkAndConfirm() async {
    if (_platformCamera == null || !_platformCamera!.needsOpenAiConfirmation) return;
    _platformCamera!.resetConfirmationFlag();

    try {
      final bytes = await _platformCamera!.captureImage();
      if (bytes == null || bytes.isEmpty) return;
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
    } catch (e) {
      debugPrint('[EmotionCamera] OpenAI confirm error: $e');
    }
  }

  Future<void> _stopCamera() async {
    _confirmTimer?.cancel();
    _confirmTimer = null;
    _platformCamera?.dispose();
    _platformCamera = null;
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
              child: _isEnabled && _platformCamera != null && _platformCamera!.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _platformCamera!.buildPreview(),
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

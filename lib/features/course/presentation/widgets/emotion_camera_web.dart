import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;

@JS('initFaceApi')
external JSPromise<JSBoolean?> _jsInitFaceApi();

@JS('detectExpression')
external JSPromise<JSString?> _jsDetectExpression(JSObject video);

@JS('captureFrame')
external JSPromise<JSString?> _jsCaptureFrame(JSObject video);

@JS('document.createElement')
external JSObject _createElement(JSString tag);


class PlatformCamera {
  JSObject? _videoElement;
  JSObject? _mediaStream;
  bool _initialized = false;
  bool _faceApiReady = false;
  String? _viewId;
  Timer? _detectTimer;

  String _lastEmotion = 'neutral';
  double _lastConfidence = 0;
  int _negativeStreak = 0;
  bool _needsConfirmation = false;
  void Function(String emotion, double confidence)? onLocalDetection;

  bool get isInitialized => _initialized;
  bool get needsOpenAiConfirmation => _needsConfirmation;
  String get lastEmotion => _lastEmotion;
  double get lastConfidence => _lastConfidence;

  void resetConfirmationFlag() => _needsConfirmation = false;

  Future<void> initialize() async {
    final constraints = {
      'video': {'facingMode': 'user', 'width': 160, 'height': 120},
      'audio': false,
    }.jsify() as JSObject;

    _mediaStream = await (_callGetUserMedia(constraints).toDart);

    _viewId = 'emotion-camera-${DateTime.now().millisecondsSinceEpoch}';
    _videoElement = _createElement('video'.toJS);

    _setVideoProps(_videoElement!, _mediaStream!);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId!,
      (int viewId) => _videoElement!,
    );

    _playVideo(_videoElement!);
    _initialized = true;

    try {
      final result = await _jsInitFaceApi().toDart;
      _faceApiReady = result?.toDart ?? false;
      debugPrint('[EmotionCamera] FaceAPI ready: $_faceApiReady');
    } catch (e) {
      debugPrint('[EmotionCamera] FaceAPI init failed: $e');
      _faceApiReady = false;
    }

    if (_faceApiReady) {
      _detectTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _detectLocal(),
      );
    }
  }

  Future<void> _detectLocal() async {
    if (_videoElement == null || !_faceApiReady) return;

    try {
      final result = await _jsDetectExpression(_videoElement!).toDart;
      if (result == null) return;

      final data = jsonDecode(result.toDart) as Map<String, dynamic>;
      final emotion = data['emotion'] as String? ?? 'neutral';
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0;

      _lastEmotion = _mapEmotion(emotion);
      _lastConfidence = confidence;

      onLocalDetection?.call(_lastEmotion, _lastConfidence);

      if (_isNegativeEmotion(_lastEmotion) && _lastConfidence >= 0.5) {
        _negativeStreak++;
      } else {
        _negativeStreak = 0;
      }

      if (_negativeStreak >= 10) {
        _needsConfirmation = true;
        _negativeStreak = 0;
      }
    } catch (e) {
      debugPrint('[EmotionCamera] Detection error: $e');
    }
  }

  String _mapEmotion(String faceApiEmotion) {
    switch (faceApiEmotion) {
      case 'sad':
      case 'fearful':
        return 'confused';
      case 'angry':
      case 'disgusted':
        return 'frustrated';
      case 'neutral':
        return 'neutral';
      case 'happy':
        return 'happy';
      case 'surprised':
        return 'focused';
      default:
        return 'neutral';
    }
  }

  bool _isNegativeEmotion(String emotion) {
    return emotion == 'confused' || emotion == 'frustrated' || emotion == 'bored';
  }

  Future<Uint8List?> captureImage() async {
    if (_videoElement == null || !_initialized) return null;

    try {
      final result = await _jsCaptureFrame(_videoElement!).toDart;
      if (result == null) return null;
      return base64Decode(result.toDart);
    } catch (e) {
      debugPrint('[EmotionCamera] Capture error: $e');
      return null;
    }
  }

  Widget buildPreview() {
    if (_viewId == null) return const SizedBox.shrink();
    return HtmlElementView(viewType: _viewId!);
  }

  void dispose() {
    _detectTimer?.cancel();
    _detectTimer = null;
    if (_mediaStream != null) {
      _stopTracks(_mediaStream!);
    }
    _mediaStream = null;
    if (_videoElement != null) {
      _pauseVideo(_videoElement!);
    }
    _videoElement = null;
    _initialized = false;
    _faceApiReady = false;
  }
}

@JS('navigator.mediaDevices.getUserMedia')
external JSPromise<JSObject> _callGetUserMedia(JSObject constraints);


void _setVideoProps(JSObject video, JSObject stream) {
  _jsSetVideoProps(video, stream);
}

@JS('_setVideoPropsHelper')
external void _jsSetVideoProps(JSObject video, JSObject stream);

void _playVideo(JSObject video) {
  _jsPlayVideo(video);
}

@JS('_playVideoHelper')
external void _jsPlayVideo(JSObject video);

void _pauseVideo(JSObject video) {
  _jsPauseVideo(video);
}

@JS('_pauseVideoHelper')
external void _jsPauseVideo(JSObject video);

void _stopTracks(JSObject stream) {
  _jsStopTracks(stream);
}

@JS('_stopTracksHelper')
external void _jsStopTracks(JSObject stream);

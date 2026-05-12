import 'dart:convert';
import 'dart:math' as math;

class ConfusionPredictor {
  List<double>? _scalerMean;
  List<double>? _scalerScale;
  List<_DenseLayer>? _layers;

  List<double>? _lrCoefficients;
  double? _lrIntercept;
  List<double>? _lrScalerMean;
  List<double>? _lrScalerScale;

  bool _mlpLoaded = false;
  bool _lrLoaded = false;

  static final ConfusionPredictor _instance = ConfusionPredictor._();
  factory ConfusionPredictor() => _instance;
  ConfusionPredictor._();

  bool get isReady => _mlpLoaded || _lrLoaded;

  void loadMlpWeights(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    _scalerMean = (data['scaler_mean'] as List).cast<double>();
    _scalerScale = (data['scaler_scale'] as List).cast<double>();

    final layersData = data['layers'] as List;
    _layers = layersData.map((l) {
      final weightsRaw = l['weights'] as List;
      final biases = (l['biases'] as List).cast<double>();
      final activation = l['activation'] as String;

      final weights = weightsRaw.map((row) {
        return (row as List).cast<double>();
      }).toList();

      return _DenseLayer(
        weights: weights,
        biases: biases,
        activation: activation,
      );
    }).toList();

    _mlpLoaded = true;
  }

  void loadLrWeights(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    _lrScalerMean = (data['scaler_mean'] as List).cast<double>();
    _lrScalerScale = (data['scaler_scale'] as List).cast<double>();
    _lrCoefficients = (data['coefficients'] as List).cast<double>();
    _lrIntercept = (data['intercept'] as num).toDouble();
    _lrLoaded = true;
  }

  double predict(Map<String, dynamic> features) {
    final input = _extractFeatureVector(features);

    if (_mlpLoaded) return _predictMlp(input);
    if (_lrLoaded) return _predictLr(input);

    return _predictRuleBased(features);
  }

  List<double> _extractFeatureVector(Map<String, dynamic> features) {
    return [
      (features['pause_count'] as num?)?.toDouble() ?? 0,
      (features['avg_pause_duration'] as num?)?.toDouble() ?? 0,
      (features['long_pause_count'] as num?)?.toDouble() ?? 0,
      (features['rewind_count'] as num?)?.toDouble() ?? 0,
      (features['rewind_same_spot'] as num?)?.toDouble() ?? 0,
      (features['speed_decrease'] as num?)?.toDouble() ?? 0,
      (features['confused_ratio'] as num?)?.toDouble() ?? 0,
      (features['frustrated_ratio'] as num?)?.toDouble() ?? 0,
      (features['emotion_transitions'] as num?)?.toDouble() ?? 0,
      (features['neg_emotion_streak'] as num?)?.toDouble() ?? 0,
      (features['quiz_score'] as num?)?.toDouble() ?? 50,
      (features['quiz_time'] as num?)?.toDouble() ?? 30,
    ];
  }

  double _predictMlp(List<double> input) {
    var x = _scaleInput(input, _scalerMean!, _scalerScale!);

    for (final layer in _layers!) {
      x = _denseForward(x, layer);
    }

    return x[0].clamp(0.0, 1.0);
  }

  double _predictLr(List<double> input) {
    final x = _scaleInput(input, _lrScalerMean!, _lrScalerScale!);

    double z = _lrIntercept!;
    for (int i = 0; i < x.length; i++) {
      z += _lrCoefficients![i] * x[i];
    }

    return _sigmoid(z);
  }

  double _predictRuleBased(Map<String, dynamic> features) {
    double score = 0;
    final pauseCount = (features['pause_count'] as num?)?.toDouble() ?? 0;
    final rewindCount = (features['rewind_count'] as num?)?.toDouble() ?? 0;
    final confusedRatio = (features['confused_ratio'] as num?)?.toDouble() ?? 0;
    final frustratedRatio = (features['frustrated_ratio'] as num?)?.toDouble() ?? 0;
    final negStreak = (features['neg_emotion_streak'] as num?)?.toDouble() ?? 0;
    final rewindSameSpot = (features['rewind_same_spot'] as num?)?.toDouble() ?? 0;

    if (pauseCount >= 3) score += 0.15;
    if (rewindCount >= 2) score += 0.2;
    if (confusedRatio >= 0.4) score += 0.25;
    if (frustratedRatio >= 0.3) score += 0.15;
    if (negStreak >= 3) score += 0.15;
    if (rewindSameSpot >= 1) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  List<double> _scaleInput(List<double> input, List<double> mean, List<double> scale) {
    return List.generate(input.length, (i) {
      final s = scale[i] == 0 ? 1.0 : scale[i];
      return (input[i] - mean[i]) / s;
    });
  }

  List<double> _denseForward(List<double> input, _DenseLayer layer) {
    final outputSize = layer.biases.length;
    final output = List<double>.filled(outputSize, 0);

    for (int j = 0; j < outputSize; j++) {
      double sum = layer.biases[j];
      for (int i = 0; i < input.length; i++) {
        sum += input[i] * layer.weights[i][j];
      }
      output[j] = sum;
    }

    switch (layer.activation) {
      case 'relu':
        for (int j = 0; j < outputSize; j++) {
          if (output[j] < 0) output[j] = 0;
        }
        break;
      case 'sigmoid':
        for (int j = 0; j < outputSize; j++) {
          output[j] = _sigmoid(output[j]);
        }
        break;
    }

    return output;
  }

  double _sigmoid(double x) {
    if (x > 20) return 1.0;
    if (x < -20) return 0.0;
    return 1.0 / (1.0 + math.exp(-x));
  }
}

class _DenseLayer {
  final List<List<double>> weights;
  final List<double> biases;
  final String activation;

  _DenseLayer({
    required this.weights,
    required this.biases,
    required this.activation,
  });
}

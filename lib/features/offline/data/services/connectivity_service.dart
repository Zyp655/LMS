import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _controller;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get onConnectivityChanged {
    if (_controller == null) {
      _controller = StreamController<bool>.broadcast();
      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        final isOnline = results.any((r) => r != ConnectivityResult.none);
        _controller?.add(isOnline);
      });
    }
    return _controller!.stream;
  }

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller?.close();
    _controller = null;
  }
}

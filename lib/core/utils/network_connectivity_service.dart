import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  StreamController<bool>? _connectionChangeController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isInitializing = false;

  Stream<bool> get onConnectionChanged {
    _connectionChangeController ??= StreamController<bool>.broadcast();
    return _connectionChangeController!.stream;
  }

  void initialize() {
    if (_isInitializing) return;
    _isInitializing = true;

    _connectionChangeController ??= StreamController<bool>.broadcast();
    _connectivitySubscription?.cancel();

    try {
      final connectivity = Connectivity();
      _connectivitySubscription = connectivity.onConnectivityChanged.listen(
        (results) {
          final isConnected = results.any((result) => result != ConnectivityResult.none);
          if (_connectionChangeController != null && !_connectionChangeController!.isClosed) {
            _connectionChangeController!.add(isConnected);
          }
        },
        onError: (_) {},
      );
    } catch (_) {
      _isInitializing = false;
    }
  }

  Future<bool> checkConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _connectionChangeController?.close();
    _connectionChangeController = null;
    _isInitializing = false;
  }
}

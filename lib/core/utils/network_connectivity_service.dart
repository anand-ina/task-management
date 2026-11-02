import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

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
        (results) async {
          final isConnected = await checkConnection();
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

  /// Reliable check:
  /// 1. Instant check of network interface (< 5ms)
  /// 2. Check reachability to dev-task-api.srivyn.in (or DNS lookup)
  Future<bool> checkConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final hasInterface = results.any((result) => result != ConnectivityResult.none);
      if (!hasInterface) {
        return false;
      }

      if (kIsWeb) return true;

      try {
        final lookupResults = await InternetAddress.lookup('dev-task-api.srivyn.in')
            .timeout(const Duration(milliseconds: 2500));
        return lookupResults.isNotEmpty && lookupResults[0].rawAddress.isNotEmpty;
      } catch (_) {
        // Fallback socket connection to verify if general internet works
        try {
          final socket = await Socket.connect(
            '8.8.8.8',
            53,
            timeout: const Duration(milliseconds: 2000),
          );
          socket.destroy();
          return true;
        } catch (_) {
          return false;
        }
      }
    } catch (_) {
      return false;
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

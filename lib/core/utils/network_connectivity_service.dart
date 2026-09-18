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
          final hasInterface = results.any((result) => result != ConnectivityResult.none);
          bool isConnected = hasInterface;
          if (hasInterface && !kIsWeb) {
            try {
              final lookup = await InternetAddress.lookup('google.com')
                  .timeout(const Duration(seconds: 3));
              isConnected = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
            } on SocketException catch (_) {
              isConnected = false;
            } catch (_) {
              isConnected = true;
            }
          }
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
      final hasInterface = results.any((result) => result != ConnectivityResult.none);
      if (!hasInterface) {
        return false;
      }
      if (!kIsWeb) {
        try {
          final lookup = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 3));
          return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
        } on SocketException catch (_) {
          return false;
        } catch (_) {
          return true; // fallback to interface presence if timeout
        }
      }
      return true;
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

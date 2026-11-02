import 'dart:io';
import 'package:dio/dio.dart';

/// Formats any error/exception into a user-friendly message.
/// Converts technical DioException / connection errors into "Internet not available".
String formatErrorMessage(dynamic error, {String defaultMessage = 'Internet not available'}) {
  if (error == null) return defaultMessage;

  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.error is SocketException) {
      return 'Internet not available';
    }
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      if (msg is List) return msg.join(', ');
      if (msg.toString().trim().isNotEmpty) return msg.toString();
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      final lower = error.message!.toLowerCase();
      if (lower.contains('connection') ||
          lower.contains('socket') ||
          lower.contains('network') ||
          lower.contains('failed host lookup') ||
          lower.contains('host lookup')) {
        return 'Internet not available';
      }
      return error.message!;
    }
  }

  final str = error.toString();
  final lower = str.toLowerCase();
  if (lower.contains('dioexception') ||
      lower.contains('connection error') ||
      lower.contains('connection err') ||
      lower.contains('connectionerr') ||
      lower.contains('socketexception') ||
      lower.contains('network is unreachable') ||
      lower.contains('failed host lookup') ||
      lower.contains('host lookup') ||
      lower.contains('connection timed out') ||
      lower.contains('connecttimeout') ||
      lower.contains('receivetimeout') ||
      lower.contains('sendtimeout') ||
      lower.contains('no internet') ||
      lower.contains('clientexception') ||
      lower.contains('failed to connect') ||
      lower.contains('network error')) {
    return 'Internet not available';
  }

  if (str.startsWith('Exception: ')) {
    final trimmed = str.substring(11).trim();
    final trimmedLower = trimmed.toLowerCase();
    if (trimmedLower.contains('dioexception') ||
        trimmedLower.contains('connection error') ||
        trimmedLower.contains('connection err') ||
        trimmedLower.contains('socketexception') ||
        trimmedLower.contains('failed host lookup') ||
        trimmedLower.contains('network')) {
      return 'Internet not available';
    }
    return trimmed;
  }

  return str;
}

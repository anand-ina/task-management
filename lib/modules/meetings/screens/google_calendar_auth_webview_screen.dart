import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';

class GoogleCalendarAuthWebViewScreen extends StatefulWidget {
  final String authUrl;

  const GoogleCalendarAuthWebViewScreen({
    super.key,
    required this.authUrl,
  });

  @override
  State<GoogleCalendarAuthWebViewScreen> createState() =>
      _GoogleCalendarAuthWebViewScreenState();
}

class _GoogleCalendarAuthWebViewScreenState
    extends State<GoogleCalendarAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _hasHandledResult = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
              });
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
            _checkIntercept(url);
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _checkIntercept(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkIntercept(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('[GoogleCalendarAuth] WebResourceError: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  bool _checkIntercept(String url) {
    if (_hasHandledResult) return true;

    debugPrint('[GoogleCalendarAuth] Intercept checking URL: $url');

    if (url.contains('google_connected=true')) {
      _hasHandledResult = true;
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return true;
    }

    if (url.contains('google_error=')) {
      _hasHandledResult = true;
      String errorMsg = 'Google Calendar connection failed.';
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final queryParam = uri.queryParameters['google_error'];
        if (queryParam != null && queryParam.isNotEmpty) {
          errorMsg = Uri.decodeComponent(queryParam);
        }
      }
      if (mounted) {
        Navigator.of(context).pop(errorMsg);
      }
      return true;
    }

    // If redirected to meetings page without error parameter
    if ((url.contains('/meetings') || url.contains('dev-task.srivyn.in')) &&
        !url.contains('accounts.google.com') &&
        !url.contains('oauth')) {
      _hasHandledResult = true;
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Text(
              'Google Sign In',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  color: AppColors.primary(context),
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

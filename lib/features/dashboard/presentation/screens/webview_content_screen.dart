import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';

class WebViewContentScreen extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback? onBack;

  const WebViewContentScreen({
    super.key,
    required this.url,
    required this.title,
    this.onBack,
  });

  @override
  State<WebViewContentScreen> createState() => _WebViewContentScreenState();
}

class _WebViewContentScreenState extends State<WebViewContentScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _clearBrowsingData();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(const Duration(minutes: 2), () {
      if (_isLoading && mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Connection timed out. Please check your internet connection and try again.';
        });
      }
    });
  }

  // Clear web cache and cookies
  Future<void> _clearBrowsingData() async {
    await CookieManager.instance().deleteAllCookies();
    if (Platform.isAndroid || Platform.isIOS) {
      await InAppWebViewController.clearAllCache();
      if (Platform.isAndroid) {
        await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(
          true,
        );
      }
    }
  }

  // Retry loading the page
  void _retryLoading() {
    try {
      _timeoutTimer?.cancel();
      _startTimeoutTimer();

      setState(() {
        _hasError = false;
        _errorMessage = '';
        _isLoading = true;
      });

      if (_webViewController != null) {
        // Instead of using reload() which causes MissingPluginException
        // Load the original URL again
        try {
          _webViewController!.reload();
        } catch (e) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Error reloading page: $e. Please try again.';
          });
        }
      }
    } catch (e) {
      // Handle any errors during retry
      setState(() {
        _hasError = true;
        _errorMessage = 'Error reloading page: $e. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!_hasError)
          InAppWebView(
            key: webViewKey,
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
              cacheEnabled: true,
              preferredContentMode: UserPreferredContentMode.RECOMMENDED,
            ),
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
              _timeoutTimer?.cancel();
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _loadingProgress = progress / 100;
              });
            },
            onReceivedError: (controller, request, error) {
              // setState(() {
              //   _hasError = true;
              //   _isLoading = false;
              //   _errorMessage =
              //       'Failed to load page. Please check your connection and try again.';
              // });
              _timeoutTimer?.cancel();
            },
          ),
        if (_hasError)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48.0),
                    child: ElevatedButton(
                      onPressed: _retryLoading,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_isLoading && !_hasError) _buildShimmerLoading(context),

        // Original loading indicator (commented out)
        /*
        if (_isLoading && !_hasError)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: _loadingProgress > 0.0 ? _loadingProgress : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading... ${(_loadingProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        */
      ],
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header shimmer
                Container(
                  height: 24,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),

                // List tiles shimmer
                for (int i = 0; i < 10; i++) ...[
                  _buildShimmerListTile(),
                  const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerListTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

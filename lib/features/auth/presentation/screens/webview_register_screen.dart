import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/network_urls.dart';
import '../../../../core/theme/app_theme.dart';

class WebViewRegisterScreen extends StatefulWidget {
  const WebViewRegisterScreen({super.key});

  @override
  State<WebViewRegisterScreen> createState() => _WebViewRegisterScreenState();
}

class _WebViewRegisterScreenState extends State<WebViewRegisterScreen> {
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
        _webViewController!.reload();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error reloading page: $e. Please try again.';
      });
    }
  }

  // Open registration page in external browser
  Future<void> _openInExternalBrowser() async {
    final Uri url = Uri.parse(NetworkUrls.registerPage);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage =
            'Could not open browser. Please try again or use the in-app registration form.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (!_hasError)
              InAppWebView(
                key: webViewKey,
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                    useShouldOverrideUrlLoading: true,
                    mediaPlaybackRequiresUserGesture: false,
                    javaScriptEnabled: true,
                    cacheEnabled: false,
                    clearCache: true,
                    preferredContentMode: UserPreferredContentMode.MOBILE,
                    incognito: true,
                  ),
                ),
                initialUrlRequest: URLRequest(
                  url: WebUri(NetworkUrls.registerPage),
                  headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
                ),
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
                    if (progress == 100) {
                      _isLoading = false;
                    }
                  });
                },
                onLoadError: (controller, url, code, message) {
                  if (code != -999) {
                    // -999 is a normal iOS cancelation
                    setState(() {
                      _hasError = true;
                      _errorMessage =
                          'Failed to load registration page. Error $code: $message';
                    });
                  }
                  _timeoutTimer?.cancel();
                },
              ),

            // Show error message if there's an error
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
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
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _openInExternalBrowser,
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Open in Browser'),
                      ),
                    ],
                  ),
                ),
              ),

            // Show shimmer loading effect
            if (_isLoading && !_hasError) _buildShimmerLoading(context),
          ],
        ),
      ),
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
                // Form title shimmer
                Container(
                  width: 200,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 32),

                // Form field shimmer 1
                _buildFormFieldShimmer(),
                const SizedBox(height: 24),

                // Form field shimmer 2
                _buildFormFieldShimmer(),
                const SizedBox(height: 24),

                // Form field shimmer 3
                _buildFormFieldShimmer(),
                const SizedBox(height: 24),

                // Form field shimmer 4
                _buildFormFieldShimmer(),
                const SizedBox(height: 32),

                // Button shimmer
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFieldShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Container(
          width: 100,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        // Input field
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

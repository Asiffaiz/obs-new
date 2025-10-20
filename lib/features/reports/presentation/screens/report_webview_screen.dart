import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Separate StatefulWidget for the session expiry overlay
class SessionExpiryOverlay extends StatefulWidget {
  final int remainingSeconds;
  final VoidCallback onExtendSession;
  final VoidCallback onSignOut;

  const SessionExpiryOverlay({
    super.key,
    required this.remainingSeconds,
    required this.onExtendSession,
    required this.onSignOut,
  });

  @override
  State<SessionExpiryOverlay> createState() => _SessionExpiryOverlayState();
}

class _SessionExpiryOverlayState extends State<SessionExpiryOverlay> {
  late Timer _countdownTimer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.remainingSeconds;

    // Start countdown timer for dialog
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onExtendSession(); // Auto-refresh when time is up
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format remaining time as mm:ss
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final formattedTime = "$minutes:$seconds";

    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: screenSize.width,
        height: screenSize.height,
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            width: screenSize.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.grey, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Session Expiring Soon',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.access_time, size: 50, color: Colors.blueGrey),
                const SizedBox(height: 16),
                const Text(
                  'Your session will expire in:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Do you want to stay signed in and extend your session?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Text(
                    'Note: You will be automatically logged out if no action is taken.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.brown, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: widget.onSignOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Sign Out',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: widget.onExtendSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Extend Session',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const ReportWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<ReportWebViewScreen> createState() => _ReportWebViewScreenState();
}

class _ReportWebViewScreenState extends State<ReportWebViewScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  // Session expiry settings
  static const int sessionDurationMinutes = 10; // For testing, set to 1 minute
  static const int warningThresholdSeconds =
      30; // Show warning when 30 seconds left

  Timer? _sessionTimer;
  int _remainingSeconds = sessionDurationMinutes * 60;
  bool _isDialogShown = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startSessionTimer();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _startSessionTimer() {
    // Make sure any existing timer is cancelled
    if (_sessionTimer != null && _sessionTimer!.isActive) {
      _sessionTimer!.cancel();
    }

    // Reset the timer state
    _remainingSeconds = sessionDurationMinutes * 60;
    _isDialogShown = false;

    // Remove any existing overlay
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Start a new timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
      }

      // Show warning dialog when threshold is reached
      if (_remainingSeconds == warningThresholdSeconds && !_isDialogShown) {
        _showExpiryWarningOverlay();
      }

      // Auto-refresh when time is up
      if (_remainingSeconds <= 0 && !_isDialogShown) {
        timer.cancel();
        _refreshWebView();
      }
    });
  }

  void _refreshWebView() {
    // Cancel existing timer first
    _sessionTimer?.cancel();

    // Reset the timer variables
    _remainingSeconds = sessionDurationMinutes * 60;
    _isDialogShown = false;

    // Reload the webview
    _webViewController.reload();

    // Start a new timer after a short delay to ensure the page has started reloading
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _startSessionTimer();
      }
    });
  }

  // Using a separate StatefulWidget for the session expiry overlay
  void _showExpiryWarningOverlay() {
    _isDialogShown = true;

    // Show the overlay as a full-screen widget using OverlayEntry
    OverlayState? overlayState = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder:
          (context) => SessionExpiryOverlay(
            remainingSeconds: _remainingSeconds,
            onExtendSession: () {
              _overlayEntry?.remove();
              _overlayEntry = null;
              _isDialogShown = false;
              _refreshWebView();
            },
            onSignOut: () {
              _overlayEntry?.remove();
              _overlayEntry = null;
              _isDialogShown = false;

              // Use Future.microtask to avoid the setState after dispose error
              Future.microtask(() {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              });
            },
          ),
    );

    overlayState.insert(_overlayEntry!);
  }

  void _initWebView() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('WebView error: ${error.description}');
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _handleBackPress() async {
    if (await _webViewController.canGoBack()) {
      _webViewController.goBack();
      return false; // Don't close the screen
    }
    return true; // Allow screen to close
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon:
                Platform.isIOS
                    ? const Icon(Icons.arrow_back_ios_new_rounded)
                    : const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _webViewController.canGoBack()) {
                _webViewController.goBack();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (_isLoading) const DashboardShimmer(),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicealerts_obs/features/agreements/domain/models/agreement_model.dart';
import 'package:voicealerts_obs/features/agreements/helpers/agreement_replace_content.dart';
import 'package:voicealerts_obs/features/agreements/presentation/widgets/read_local_file.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Replace this with your actual model

class AgreementFormWebView extends StatefulWidget {
  final AgreementModel agreement;

  const AgreementFormWebView({required this.agreement, super.key});

  @override
  State<AgreementFormWebView> createState() => AgreementFormWebViewState();
}

class AgreementFormWebViewState extends State<AgreementFormWebView> {
  late final WebViewController _controller;

  String _htmlContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHtmlFromAssets();

    _controller =
        WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  Future<void> _loadHtmlFromAssets() async {
    try {
      final htmlContent = await getReplaceContentData(
        widget.agreement.content,
        widget.agreement.signatoryDetails,
      );

      if (kDebugMode) print(htmlContent);

      if (mounted) {
        setState(() {
          _htmlContent = htmlContent;
          _isLoading = false;
        });

        // Load the content into WebView after it's ready
        _controller.loadHtmlString(_htmlContent);
      }
    } catch (e) {
      setState(() {
        _htmlContent =
            '<p>Error loading agreement content: ${e.toString()}</p>';
        _isLoading = false;
      });

      _controller.loadHtmlString(_htmlContent);
    }
  }

  Future<String> saveHtmlForRuntimeView(
    String htmlContent,
    String filename,
  ) async {
    final tempDir =
        await getTemporaryDirectory(); // e.g., /data/user/0/com.example.app/cache
    final file = File('${tempDir.path}/$filename.html');

    await file.writeAsString(htmlContent);
    print('Saved at: ${file.path}');
    return file.path;
  }

  void openHtmlFileInBrowser(String filePath) async {
    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("Can't launch file in browser");
    }
  }

  // Future<String> getHtmlBack() async {

  //   try {
  //     // 1. Inject JavaScript to set input/select/textarea values into the DOM
  //     final js = '''
  //           (function() {
  //             // Sync input values
  //             document.querySelectorAll("input").forEach(el => {
  //               if (el.type === "checkbox" || el.type === "radio") {
  //                 if (el.checked) {
  //                   el.setAttribute("checked", "checked");
  //                 } else {
  //                   el.removeAttribute("checked");
  //                 }
  //               } else {
  //                 el.setAttribute("value", el.value);
  //               }
  //             });

  //             // Sync textarea values
  //             document.querySelectorAll("textarea").forEach(el => {
  //               el.innerHTML = el.value;
  //             });

  //             // Sync select dropdowns
  //             document.querySelectorAll("select").forEach(el => {
  //               Array.from(el.options).forEach(opt => {
  //                 if (opt.selected) {
  //                   opt.setAttribute("selected", "selected");
  //                 } else {
  //                   opt.removeAttribute("selected");
  //                 }
  //               });
  //             });
  //           })();
  //           ''';

  //     await _controller.runJavaScript(js);

  //     // Now fetch the updated DOM
  //     final result = await _controller.runJavaScriptReturningResult(
  //       "document.documentElement.outerHTML",
  //     );

  //     // Decode if needed
  //     final cleanHtml = jsonDecode(result.toString());

  //     // print("✅ User-filled HTML:\n$cleanHtml");

  //     return cleanHtml;
  //   } catch (e) {
  //     print("❌ Error getting filled HTML: $e");
  //     return '';
  //   }
  // }

  Future<String> getHtmlBack() async {
    try {
      // Inject JS to sync user inputs
      final js = '''
      (function() {
        document.querySelectorAll("input").forEach(el => {
          if (el.type === "checkbox" || el.type === "radio") {
            if (el.checked) {
              el.setAttribute("checked", "checked");
            } else {
              el.removeAttribute("checked");
            }
          } else {
            el.setAttribute("value", el.value);
          }
        });

        document.querySelectorAll("textarea").forEach(el => {
          el.innerHTML = el.value;
        });

        document.querySelectorAll("select").forEach(el => {
          Array.from(el.options).forEach(opt => {
            if (opt.selected) {
              opt.setAttribute("selected", "selected");
            } else {
              opt.removeAttribute("selected");
            }
          });
        });
      })();
    ''';

      await _controller.runJavaScript(js);

      final result = await _controller.runJavaScriptReturningResult(
        "document.documentElement.outerHTML",
      );

      String cleanHtml;

      if (Platform.isIOS) {
        // iOS: result is already a plain string
        cleanHtml = result.toString();
      } else if (Platform.isAndroid) {
        // Android: result is JSON encoded string
        cleanHtml = jsonDecode(result.toString());
      } else {
        cleanHtml = result.toString();
      }

      return cleanHtml;
    } catch (e) {
      print("❌ Error getting filled HTML: $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : WebViewWidget(controller: _controller);
  }
}

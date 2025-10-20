import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/common_webview.dart';

class ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String text;
  final Map<String, String>? links;
  final bool isRequired;
  final String? errorText;

  const ConsentCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.text,
    this.links,
    this.isRequired = false,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildRichText(context),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRichText(BuildContext context) {
    if (links == null || links!.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      );
    }

    final textSpans = <TextSpan>[];
    final parts = text.split(
      RegExp(links!.keys.map((key) => RegExp.escape(key)).join('|')),
    );

    int currentIndex = 0;
    for (int i = 0; i < parts.length; i++) {
      // Add regular text
      textSpans.add(
        TextSpan(
          text: parts[i],
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      );

      // Add link if not the last part
      if (i < parts.length - 1) {
        // Find which link key appears after this part
        final linkText = _findLinkAfterPart(
          text,
          parts[i],
          currentIndex,
          links!.keys.toList(),
        );
        currentIndex += parts[i].length + (linkText?.length ?? 0);

        if (linkText != null && links!.containsKey(linkText)) {
          final url = links![linkText]!;
          textSpans.add(
            TextSpan(
              text: linkText,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
                decoration: TextDecoration.underline,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () async {
                      // if (await canLaunchUrl(Uri.parse(url))) {
                      //   await launchUrl(Uri.parse(url));
                      // }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CommonWebView(
                                url: url,
                                title: 'Privacy policy',
                              ),
                        ),
                      );
                    },
            ),
          );
        }
      }
    }

    return RichText(text: TextSpan(children: textSpans));
  }

  String? _findLinkAfterPart(
    String text,
    String part,
    int startIndex,
    List<String> linkKeys,
  ) {
    final subText = text.substring(startIndex + part.length);
    for (final key in linkKeys) {
      if (subText.startsWith(key)) {
        return key;
      }
    }
    return null;
  }
}

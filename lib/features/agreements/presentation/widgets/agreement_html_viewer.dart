// import 'package:flutter/material.dart';

// // import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
// import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
// import 'package:voicealerts_obs/features/agreements/helpers/agreement_replace_content.dart';
// import '../../domain/models/agreement_model.dart';

// class AgreementHtmlViewer extends StatefulWidget {
//   final AgreementModel agreement;
//   final ScrollController? scrollController;
//   final Function(bool)? onScrolledToBottom;

//   const AgreementHtmlViewer({
//     super.key,
//     required this.agreement,
//     this.scrollController,
//     this.onScrolledToBottom,
//   });

//   @override
//   State<AgreementHtmlViewer> createState() => _AgreementHtmlViewerState();
// }

// class _AgreementHtmlViewerState extends State<AgreementHtmlViewer> {
//   String _htmlContent = '';
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadHtmlFromAssets();
//   }

//   Future<void> _loadHtmlFromAssets() async {
//     try {
//       // In a real app, you would use the agreement's content or a path to the specific HTML file
//       // For now, we're using a sample file from assets
//       // final String htmlContent = await rootBundle.loadString(
//       //   'assets/Agreement_sample11.html',
//       // );
//       // if (kDebugMode) {
//       //   print(htmlContent);
//       // }

//       final htmlContent = await getReplaceContentData(
//         widget.agreement.content,
//         widget.agreement.signatoryDetails,
//       );
//       print(htmlContent);
//       if (mounted) {
//         setState(() {
//           // _htmlContent = htmlContent;
//           _htmlContent = htmlContent;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _htmlContent =
//               '<p>Error loading agreement content: ${e.toString()}</p>';
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return _isLoading
//         ? const Center(child: CircularProgressIndicator())
//         : SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10.0),
//             child:
//              HtmlWidget(
//               _htmlContent,
//               enableCaching: true,
//               buildAsync: true,
//             ),
//             // Html(
//             //   //  shrinkWrap: true,
//             //   data: _htmlContent,
//             // ),
//           ),
//           // Html(
//           //   //  shrinkWrap: true,
//           //   data: _htmlContent,

//           //   extensions: [
//           //     TagWrapExtension(
//           //       tagsToWrap: {"table"},
//           //       builder: (child) {
//           //         return SingleChildScrollView(
//           //           scrollDirection: Axis.horizontal,
//           //           child: child,
//           //         );
//           //       },
//           //     ),
//           //     const TableHtmlExtension(),
//           //   ],

//           // style: {
//           //   "p.fancy": Style(
//           //     textAlign: TextAlign.left,
//           //     padding: HtmlPaddings(
//           //       top: HtmlPadding(16),
//           //       bottom: HtmlPadding(16),
//           //       left: HtmlPadding(16),
//           //       right: HtmlPadding(16),
//           //     ),
//           //     backgroundColor: Colors.grey,
//           //     //   margin: Margins(
//           //     //     left: Margin(50, Unit.px),
//           //     //     right: Margin.auto(),
//           //     //   ),
//           //     //  // width: Width(300, Unit.px),
//           //     //   fontWeight: FontWeight.bold,
//           //   ),
//           // },
//         );
//   }
// }

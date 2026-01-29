import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';

import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/utils/validators.dart';
import 'package:voicealerts_obs/core/widgets/custome_pdf_viewer.dart';
import 'package:voicealerts_obs/features/products/domain/models/product_model.dart';
import '../../../../config/routes.dart';

void showProductDetailsModal({
  required BuildContext context,
  required String summary,
  required String description,
  required ProductModel product,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _ProductDetailsModalContent(
          summary: summary,
          description: description,
          product: product,
        ),
      );
    },
  );
}

class _ProductDetailsModalContent extends StatelessWidget {
  final String summary;
  final String description;
  final ProductModel product;

  const _ProductDetailsModalContent({
    required this.summary,
    required this.description,
    required this.product,
  });

  bool get _hasPendingAgreement {

    return product.agreementAccountno.trim().isNotEmpty &&
        product.isSigned == false;
  }

  /// Check if order buttons should be shown
  bool get _shouldShowOrderButtons {
    // Don't show if coming soon
    if (product.comingSoon == 1) return false;
    // Don't show if there's a pending agreement
    if (_hasPendingAgreement) return false;
    return true;
  }

  /// Check if form order should be shown (when form_accountno and form_link are present)
  bool get _shouldShowFormOrder {
    return product.formAccountno.trim().isNotEmpty &&
        product.formLink.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  if (product.comingSoon == 1) ...[
                    _buildComingSoonMessage(context),
                    const SizedBox(height: 16),
                  ],
                  if (_hasPendingAgreement) ...[
                    _buildPendingAgreementMessage(context),
                    const SizedBox(height: 16),
                  ],
                  product.comingSoon == 1
                      ? const SizedBox.shrink()
                      : product.rateDeckPricing == 1
                      ? _buildViewRatedecButton(context)
                      : _buildPriceInfoRow(
                        'Price:',
                        Validators.buildPriceWithCurrencySign(
                          product.rate.toString(),
                        ),
                        AppColors.primaryColor,
                      ),
                  const SizedBox(height: 16),
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  if (product.rateDeckPricing != 1) ...[
                    const SizedBox(height: 8),
                    _buildRates(product.miscellaneousRates, product.otherRates),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Html(data: description),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildActionButtons(context),
          ),
        ],
      ),
    );
  }

  /// Check if a miscellaneous rate has valid data
  bool _hasValidMiscellaneousRate(MiscellaneousRates rate) {
    return (rate.miscTitle.isNotEmpty ||
        rate.miscType.isNotEmpty ||
        rate.miscRate > 0);
  }

  /// Check if an other rate has valid data
  bool _hasValidOtherRate(OtherRates rate) {
    return (rate.genericTitle.isNotEmpty ||
        rate.genericType.isNotEmpty ||
        rate.payType.isNotEmpty ||
        rate.genericRate > 0);
  }

  /// Check if miscellaneous rates list has any valid rates
  bool _hasValidMiscellaneousRates(List<MiscellaneousRates> rates) {
    if (rates.isEmpty) return false;
    return rates.any((rate) => _hasValidMiscellaneousRate(rate));
  }

  /// Check if other rates list has any valid rates
  bool _hasValidOtherRates(List<OtherRates> rates) {
    if (rates.isEmpty) return false;
    return rates.any((rate) => _hasValidOtherRate(rate));
  }

  Widget _buildRates(
    List<MiscellaneousRates> miscellaneousRates,
    List<OtherRates> otherRates,
  ) {
    final hasOtherRates = _hasValidOtherRates(otherRates);
    final hasMiscRates = _hasValidMiscellaneousRates(miscellaneousRates);

    // If both are empty, don't show anything
    if (!hasOtherRates && !hasMiscRates) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show Other Service Rates section if it has valid data
        if (hasOtherRates) ...[
          const Text(
            'Other Service Rates',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          _buildOtherRates(otherRates),
        ],
        // Only show divider if both sections are present
        if (hasOtherRates && hasMiscRates) ...[
          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 4),
        ],
        // Only show Miscellaneous Rates section if it has valid data
        if (hasMiscRates) ...[
          const Text(
            'Miscellaneous Rates',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          _buildMiscellaneousRates(miscellaneousRates),
        ],
      ],
    );
  }

  Widget _buildMiscellaneousRates(List<MiscellaneousRates> miscellaneousRates) {
    // Filter out invalid rates (all null/empty)
    final validRates =
        miscellaneousRates
            .where((rate) => _hasValidMiscellaneousRate(rate))
            .toList();

    if (validRates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children:
          validRates.asMap().entries.map((entry) {
            final index = entry.key;
            final rate = entry.value;
            final isLast = index == validRates.length - 1;

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.agreementCardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rate.miscTitle.isNotEmpty)
                    _buildInfoRow(
                      "Title: ",
                      rate.miscTitle,
                      AppColors.primaryColor,
                    ),
                  if (rate.miscTitle.isNotEmpty &&
                      (rate.miscType.isNotEmpty || rate.miscRate > 0))
                    const SizedBox(height: 8),
                  if (rate.miscType.isNotEmpty)
                    _buildInfoRow(
                      "Rate Type: ",
                      rate.miscType,
                      AppColors.primaryColor,
                    ),
                  if (rate.miscType.isNotEmpty && rate.miscRate > 0)
                    const SizedBox(height: 8),
                  if (rate.miscRate > 0)
                    _buildInfoRow(
                      "Rate: ",
                      Validators.buildPriceWithCurrencySign(
                        rate.miscRate.toString(),
                      ),
                      AppColors.primaryColor,
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildOtherRates(List<OtherRates> otherRates) {
    // Filter out invalid rates (all null/empty)
    final validRates =
        otherRates.where((rate) => _hasValidOtherRate(rate)).toList();

    if (validRates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children:
          validRates.asMap().entries.map((entry) {
            final index = entry.key;
            final rate = entry.value;
            final isLast = index == validRates.length - 1;

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.agreementCardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rate.genericTitle.isNotEmpty)
                    _buildInfoRow(
                      "Title: ",
                      rate.genericTitle,
                      AppColors.primaryColor,
                    ),
                  if (rate.genericTitle.isNotEmpty &&
                      (rate.payType.isNotEmpty || rate.genericRate > 0))
                    const SizedBox(height: 8),
                  if (rate.payType.isNotEmpty)
                    _buildInfoRow(
                      "Charge Type: ",
                      rate.payType,
                      AppColors.primaryColor,
                    ),
                  if (rate.payType.isNotEmpty && rate.genericRate > 0)
                    const SizedBox(height: 8),
                  if (rate.genericRate > 0)
                    _buildInfoRow(
                      'Price: ',
                      Validators.buildPriceWithCurrencySign(
                        rate.genericRate.toString(),
                      ),
                      AppColors.primaryColor,
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildViewRatedecButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {
              if (product.documentUrl.isNotEmpty) {
                // Construct full URL if needed
                String fullUrl = product.documentUrl;
                if (!fullUrl.startsWith('http://') &&
                    !fullUrl.startsWith('https://')) {
                  fullUrl =
                      'https://dev-agents.onboardsoft.me/files_data/products/$fullUrl';
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CustomPdfViewer(
                          url: fullUrl,
                          title:
                              product.documentTitle.isNotEmpty
                                  ? product.documentTitle
                                  : 'Rate Deck',
                        ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rate deck document not available'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(4),
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'View Ratedec',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonMessage(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAgreementMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your agreement (${product.productTitle}) for this service is pending sign. Please sign this agreement to fully access and use this service.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Keep current behavior for now; we’ll adjust navigation later
                Navigator.of(context).pop(); // Close the modal first
                context.push(AppRoutes.signedAgreements);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Click Here to sign this agreement',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Don't show order buttons if coming soon or pending agreement
    if (!_shouldShowOrderButtons) {
      return Align(
        alignment: Alignment.bottomRight,
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Close'),
        ),
      );
    }

    // Show order buttons
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: const Text('Close'),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: ElevatedButton(
            onPressed: () => _handleOrderAction(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _shouldShowFormOrder ? 'Form Order' : 'Order Now',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  void _handleOrderAction(BuildContext context) {
    if (_shouldShowFormOrder) {
      // Handle Form Order navigation
      // TODO: Navigate to form screen with formAccountno and formLink
      Navigator.of(context).pop(); // Close modal first
      // Example navigation (adjust based on your routing):
      // context.push(
      //   AppRoutes.formScreen,
      //   extra: {
      //     'formAccountNo': product.formAccountno,
      //     'formLink': product.formLink,
      //   },
      // );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Form Order: ${product.formAccountno} - ${product.formLink}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Handle Order Now action
      Navigator.of(context).pop(); // Close modal first
      // TODO: Implement Order Now navigation/action
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order Now functionality will be implemented'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class ExpandableText extends StatefulWidget {
  final String summary;
  final String description;
  final int maxLines;
  final ProductModel product;

  const ExpandableText({
    super.key,
    required this.summary,
    required this.description,
    this.maxLines = 3,
    required this.product,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  late TextPainter _textPainter;
  // bool _isTextOverflowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextOverflow();
    });
  }

  void _checkTextOverflow() {
    final textSpan = TextSpan(
      text: widget.summary,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
      ),
    );

    _textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: widget.maxLines,
    );

    _textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 64);

    setState(() {});
  }

  void _showFullTextModal() {
    showProductDetailsModal(
      context: context,
      summary: widget.summary,
      description: widget.description,
      product: widget.product,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.summary,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // if (_isTextOverflowing)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: GestureDetector(
            onTap: _showFullTextModal,
            child: Text(
              'Show more',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

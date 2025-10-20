import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/utils/validators.dart';
import 'package:voicealerts_obs/features/products/domain/models/product_model.dart';

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
  bool _isTextOverflowing = false;

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

    setState(() {
      _isTextOverflowing = _textPainter.didExceedMaxLines;
    });
  }

  void _showFullTextModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: _buildModalContent(context),
        );
      },
    );
  }

  Widget _buildModalContent(BuildContext context) {
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
                  _buildPriceInfoRow(
                    'Price:',
                    Validators.buildPriceWithCurrencySign(
                      widget.product.rate.toString(),
                    ),
                    AppColors.primaryColor,
                  ),
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
                    widget.summary,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  _buildRates(
                    widget.product.miscellaneousRates,
                    widget.product.otherRates,
                  ),

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
                  // Text(
                  //   widget.description,
                  //   style: const TextStyle(fontSize: 14, color: Colors.black87),
                  // ),
                  Html(data: widget.description),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
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

  Widget _buildRates(
    List<MiscellaneousRates> miscellaneousRates,
    List<OtherRates> otherRates,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 4),
        const Divider(),
        const SizedBox(height: 4),
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
    );
  }

  Widget _buildMiscellaneousRates(List<MiscellaneousRates> miscellaneousRates) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.agreementCardBorderColor),
      ),
      child: Column(
        children:
            miscellaneousRates
                .map(
                  (rate) => Column(
                    children: [
                      _buildInfoRow(
                        "Title: ",
                        rate.miscTitle,
                        AppColors.primaryColor,
                      ),
                      _buildInfoRow(
                        "Rate Type: ",
                        rate.miscType,
                        AppColors.primaryColor,
                      ),
                      _buildInfoRow(
                        "Rate: ",
                        Validators.buildPriceWithCurrencySign(
                          rate.miscRate.toString(),
                        ),
                        AppColors.primaryColor,
                      ),
                    ],
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildOtherRates(List<OtherRates> otherRates) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.agreementCardBorderColor),
      ),
      child: Column(
        children:
            otherRates
                .map(
                  (rate) => Column(
                    children: [
                      _buildInfoRow(
                        "Title: ",
                        rate.genericTitle,
                        AppColors.primaryColor,
                      ),
                      _buildInfoRow(
                        "Charge Type: ",
                        rate.payType,
                        AppColors.primaryColor,
                      ),

                      _buildInfoRow(
                        'Price: ',
                        Validators.buildPriceWithCurrencySign(
                          rate.genericRate.toString(),
                        ),
                        AppColors.primaryColor,
                      ),
                    ],
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
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
          style: TextStyle(
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

  Widget _buildOtherRatesInfoColumn(
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
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
}

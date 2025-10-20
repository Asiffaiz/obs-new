import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/core/widgets/custome_pdf_viewer.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/common_webview.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import 'package:voicealerts_obs/features/products/domain/models/product_model.dart';
import 'package:voicealerts_obs/features/products/presentation/bloc/product_bloc.dart';
import 'package:voicealerts_obs/features/products/presentation/bloc/product_event.dart';
import 'package:voicealerts_obs/features/products/presentation/bloc/product_state.dart';
import 'package:voicealerts_obs/features/products/presentation/widgets/expandable_text.dart';

class ProductsScreen extends StatefulWidget {
  final bool isFromBottomNav;
  const ProductsScreen({super.key, required this.isFromBottomNav});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const LoadProducts());
  }

  bool _isMarketinglink(String marketing) {
    if (marketing.isEmpty) {
      return false;
    }

    final parts = marketing.split('###');
    if (parts.length != 2) {
      return false;
    }

    final type = parts[0].trim().toLowerCase();
    final url = parts[1].trim();

    return type.isNotEmpty && url.isNotEmpty;
  }

  // Parse marketing field to extract link type and URL
  Map<String, String> _parseMarketingField(String marketing) {
    if (marketing.isEmpty) {
      return {'type': 'none', 'url': ''};
    }

    final parts = marketing.split('###');
    if (parts.length != 2) {
      return {'type': 'none', 'url': ''};
    }

    final type = parts[0].trim().toLowerCase();
    final url = parts[1].trim();

    return {'type': type, 'url': url};
  }

  // Handle ProductInfo button press
  void _handleProductInfoPress(ProductModel product) {
    final marketingData = _parseMarketingField(product.marketing);
    final type = marketingData['type']!;
    final url = marketingData['url']!;

    switch (type) {
      case 'link':
        if (url.isNotEmpty) {
          //  Navigate to WebView screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      CommonWebView(url: url, title: product.productTitle),
            ),
          );
        }
        break;
      case 'pdf':
        if (url.isNotEmpty) {
          // Navigate to PDF viewer screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      CustomPdfViewer(url: url, title: product.productTitle),
            ),
          );
        }
        break;
      case 'none':
      default:
        // Show message that no content is available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No product information available'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  // void _navigateToDocumentDetail(ProductModel product) {
  //   // Navigator.push(
  //   //   context,
  //   //   MaterialPageRoute(
  //   //     builder: (context) => ProductDetailScreen(product: product),
  //   //   ),
  //   // ).then((result) {
  //   //   // Reload documents when returning from detail screen if needed
  //   //   if (result == true) {
  //   //     context.read<DocumentBloc>().add(const LoadDocuments());
  //   //   }
  //   // });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.isFromBottomNav
              ? null
              : AppBar(title: const Text('Products & Services')),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state.status == ProductStatus.error &&
              state.errorMessage != null) {
            CustomErrorDialog.show(
              context: context,

              onRetry: () {
                Navigator.pop(context);
                context.read<ProductBloc>().add(const LoadProducts());
              },
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProductStatus.loading) {
            return const DashboardShimmer();
          }

          if (state.status == ProductStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Something went wrong please try again',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 200,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<ProductBloc>().add(const LoadProducts());
                        },
                        child: const Text('Retry'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.products.isEmpty) {
            return const Center(
              child: Text(
                'No products available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProductBloc>().add(const LoadProducts());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(state.products[index], index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, int index) {
    // String formattedDate = DateFormat(
    //   'MMMM d yyyy',
    // ).format(product);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.agreementCardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.file_copy, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.productTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2, // or more if you want
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoRow('SKU:', product.sku, AppColors.primaryColor),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Price:',
                      _buildPriceWithCurrencySign(product.rate.toString()),
                      AppColors.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoSummary(
                  'Summary:',
                  product.productSummary,
                  product.productDesc,
                  product,
                  AppColors.primaryColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _isMarketinglink(product.marketing)
                        ? _buildActionButton(
                          icon: Icons.login,
                          label: 'Product Info',
                          color: AppColors.agreementCardViewBtnColor,
                          isViewSubmissionsBtn: false,
                          onPressed: () => _handleProductInfoPress(product),
                        )
                        : const SizedBox.shrink(),

                    // _buildActionButton(
                    //   icon: Icons.shopping_cart,
                    //   label: 'Form Order',
                    //   color: AppColors.agreementCardViewBtnColor,
                    //   isViewSubmissionsBtn: false,
                    //   onPressed: () => () {},
                    // ),
                    // _buildActionButton(
                    //   icon: Icons.more_horiz,
                    //   label: 'Actions',
                    //   color: AppColors.agreementCardViewBtnColor,
                    //   isViewSubmissionsBtn: false,
                    //   onPressed: () => () {},
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildPriceWithCurrencySign(String amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_US', // You can change to your locale (e.g., 'en_GB')
      symbol: '\$', // Dollar sign
    );
    return formatter.format(double.parse(amount));
  }

  Widget _buildInfoSummary(
    String label,
    String value,
    String description,
    ProductModel product,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        ExpandableText(
          summary: value,
          description: description,
          product: product,
        ),
      ],
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

  Widget _buildActionButton({
    required IconData? icon,
    required String label,
    required Color color,
    required bool isViewSubmissionsBtn,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding:
            isViewSubmissionsBtn
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 6)
                : const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: onPressed != null ? AppColors.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isViewSubmissionsBtn ? 14 : 12,
                color: onPressed != null ? Colors.black : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

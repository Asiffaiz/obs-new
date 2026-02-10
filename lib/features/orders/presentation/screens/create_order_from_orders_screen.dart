import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/shared_prefence_keys.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/orders/data/services/sales_orders_service.dart';
import 'package:voicealerts_obs/features/orders/domain/models/payment_complete_details_model.dart';
import 'package:voicealerts_obs/features/products/data/services/product_service.dart';
import 'package:voicealerts_obs/features/products/domain/models/product_model.dart';

// Helper class to hold selected product with quantity
class _OrderProductItem {
  final ProductModel product;
  int quantity;

  _OrderProductItem({required this.product, this.quantity = 1});

  double get total => product.rate.toDouble() * quantity;
}

class CreateOrderFromOrdersScreen extends StatefulWidget {
  const CreateOrderFromOrdersScreen({super.key});

  @override
  State<CreateOrderFromOrdersScreen> createState() =>
      _CreateOrderFromOrdersScreenState();
}

class _CreateOrderFromOrdersScreenState
    extends State<CreateOrderFromOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SalesOrdersService _salesOrdersService = SalesOrdersService();
  final ProductService _productService = ProductService();
  Map<String, String> _userData = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Product selection
  List<ProductModel> _products = [];
  bool _isLoadingProducts = false;
  int _dropdownKey = 0; // Key to force dropdown rebuild

  // Selected products with quantities
  final List<_OrderProductItem> _selectedProducts = [];

  // Order form data
  double _discount = 0.0;
  double _shipping = 0.0;
  double _tax = 0.0;
  double _subtotal = 0.0;
  double _grandTotal = 0.0;

  // Order data from API
  String _orderNumber = '';
  String _issueDate = '';
  String _termsOfPayment = 'Net 60';
  String _currency = 'USD';
  String _contactPerson = '';
  String _contactEmail = '';

  // Form controllers
  final TextEditingController _orderTitleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Payment details from API
  PaymentCompleteDetailsModel? _paymentDetails;
  final Map<String, String> _bankAccountData = {
    'bankName': '',
    'accountHolderName': '',
    'accountNumber': '',
    'bankAddress': '',
    'routingNumber': '',
    'swiftCode': '',
    'iban': '',
  };

  final orderCellColor = HexColor('#F3F3F3');
  final allCellsLabelColor = HexColor('#02274D');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild when tab changes
      }
    });
    _initializeOrder();
  }

  Future<void> _initializeOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user data
      await _loadUserData();

      // Load products
      await _loadProducts();

      // Generate random order number (7 digits like "3625656")
      _orderNumber = _generateRandomOrderNumber();

      // Set issue date to today
      _issueDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

      // Initialize order title with order number
      _orderTitleController.text = 'Order - $_orderNumber';

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize order: ${e.toString()}';
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onProductSelectedForAdd(ProductModel? product) {
    if (product == null) return;

    setState(() {
      // Add product to selected list
      _selectedProducts.add(_OrderProductItem(product: product, quantity: 1));

      // Increment key to force dropdown rebuild with null value
      _dropdownKey++;

      // Calculate totals
      _calculateTotals();

      // Fetch payment details from API when first product is added
      if (_selectedProducts.length == 1) {
        final accountNo = _userData['accountno'];
        if (accountNo != null && accountNo.isNotEmpty) {
          _fetchPaymentDetails();
        }
      }
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
      _calculateTotals();
    });
  }

  void _updateProductQuantity(int index, int quantity) {
    if (quantity < 1) return;

    setState(() {
      _selectedProducts[index].quantity = quantity;
      _calculateTotals();
    });
  }

  List<ProductModel> _getAvailableProducts() {
    // Return products that are not already selected
    final selectedProductIds =
        _selectedProducts.map((item) => item.product.productId).toSet();
    return _products
        .where((product) => !selectedProductIds.contains(product.productId))
        .toList();
  }

  String _generateRandomOrderNumber() {
    // Generate a 7-digit random number
    final random = Random();
    return (1000000 + random.nextInt(9000000)).toString();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userData = {
      'comp_name': prefs.getString(SharedPreferenceKeys.companyNameKey) ?? '',
      'name': prefs.getString(SharedPreferenceKeys.nameKey) ?? '',
      'email': prefs.getString(SharedPreferenceKeys.emailKey) ?? '',
      'accountno': prefs.getString(SharedPreferenceKeys.accountNoKey) ?? '',
    };
  }

  Future<void> _fetchPaymentDetails() async {
    try {
      final paymentDetails = await _salesOrdersService
          .getPaymentCompleteDetails(
            accountNo: _userData['accountno']!,
            orderNo: _orderNumber,
          );

      setState(() {
        _paymentDetails = paymentDetails;

        // Update payment settings
        _termsOfPayment = paymentDetails.paymentSettings.paymentTerms;
        _currency = paymentDetails.paymentSettings.currency;
        _contactPerson = paymentDetails.paymentSettings.contactPerson;
        _contactEmail = paymentDetails.paymentSettings.contactEmail;

        // Parse HTML payment details from first payment method
        if (paymentDetails.paymentMethods.isNotEmpty) {
          _parsePaymentDetailsHtml(
            paymentDetails.paymentMethods[0].paymentDetails,
          );
        }
      });
    } catch (e) {
      // If API fails, use default values
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payment details: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _parsePaymentDetailsHtml(String htmlContent) {
    // Parse HTML to extract bank account details
    // The HTML format is: <p><strong>Label:</strong> Value</p>
    try {
      // Extract Bank Name
      final bankNameMatch = RegExp(
        r'<strong>Bank Name:</strong>\s*([^<]+)',
        caseSensitive: false,
      ).firstMatch(htmlContent);
      if (bankNameMatch != null) {
        _bankAccountData['bankName'] = bankNameMatch.group(1)?.trim() ?? '';
      }

      // Extract Account Holder Name
      final accountHolderMatch = RegExp(
        r'<strong>Account Holder Name:</strong>\s*([^<]+)',
        caseSensitive: false,
      ).firstMatch(htmlContent);
      if (accountHolderMatch != null) {
        _bankAccountData['accountHolderName'] =
            accountHolderMatch.group(1)?.trim() ?? '';
      }

      // Extract Account Number
      final accountNumberMatch = RegExp(
        r'<strong>Account Number:</strong>\s*([^<]+)',
        caseSensitive: false,
      ).firstMatch(htmlContent);
      if (accountNumberMatch != null) {
        _bankAccountData['accountNumber'] =
            accountNumberMatch.group(1)?.trim() ?? '';
      }

      // Extract Bank Address
      final bankAddressMatch = RegExp(
        r'<strong>Bank Address:</strong>\s*([^<]+)',
        caseSensitive: false,
      ).firstMatch(htmlContent);
      if (bankAddressMatch != null) {
        _bankAccountData['bankAddress'] =
            bankAddressMatch.group(1)?.trim() ?? '';
      }

      // Extract Routing Number
      final routingNumberMatch = RegExp(
        r'<strong>Routing Number[^<]*</strong>\s*([^<]+)',
        caseSensitive: false,
      ).firstMatch(htmlContent);
      if (routingNumberMatch != null) {
        _bankAccountData['routingNumber'] =
            routingNumberMatch.group(1)?.trim() ?? '';
      }

      // Extract SWIFT Code
      final swiftCodeMatch = RegExp(
        r'<strong>SWIFT Code[^<]*</strong>\s*([^<]+)',
        caseSensitive: false,
      ).firstMatch(htmlContent);
      if (swiftCodeMatch != null) {
        _bankAccountData['swiftCode'] = swiftCodeMatch.group(1)?.trim() ?? '';
      }

      // Extract IBAN
      final ibanMatch = RegExp(
        r'<strong>IBAN[^<]*</strong>\s*([^<]+)',
        caseSensitive: false,
      ).firstMatch(htmlContent);
      if (ibanMatch != null) {
        _bankAccountData['iban'] = ibanMatch.group(1)?.trim() ?? '';
      }
    } catch (e) {
      // If parsing fails, keep default empty values
      if (mounted) {
        debugPrint('Error parsing payment details HTML: $e');
      }
    }
  }

  void _calculateTotals() {
    setState(() {
      // Calculate subtotal from all selected products
      _subtotal = _selectedProducts.fold<double>(
        0.0,
        (sum, item) => sum + item.total,
      );
      _grandTotal = _subtotal - _discount + _shipping + _tax;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderTitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Order'),
          backgroundColor: AppColors.primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Order'),
          backgroundColor: AppColors.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeOrder,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Order',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          _buildOrderDetailsSection(),
                          _buildTabs(),
                          _buildTabContent(),
                          _buildSummarySection(),
                          const SizedBox(
                            height: 80,
                          ), // Space for action buttons
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: orderCellColor,
        borderRadius: BorderRadius.circular(8),
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
          const Text(
            'ORDER',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('ORDER NUMBER:', _orderNumber),
          const SizedBox(height: 8),
          _buildInfoRow('ISSUE DATE:', _issueDate),
          const SizedBox(height: 8),
          _buildInfoRow('FROM:', 'OnBoardSoft LLC'),
          const SizedBox(height: 8),
          _buildInfoRow(
            'COMPANY:',
            _userData['comp_name']?.isEmpty ?? true
                ? 'OBS'
                : _userData['comp_name']!,
          ),
          const SizedBox(height: 8),
          _buildInfoRow('TERMS OF PAYMENT:', _termsOfPayment),
          const SizedBox(height: 8),
          _buildInfoRow('CURRENCY:', _currency),
          const SizedBox(height: 8),
          _buildInfoRow(
            'CONTACT PERSON:',
            _contactPerson.isNotEmpty
                ? _contactPerson.toUpperCase()
                : (_userData['name']?.isEmpty ?? true
                    ? 'JAMES SMITH'
                    : _userData['name']!.toUpperCase()),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'EMAIL:',
            _contactEmail.isNotEmpty
                ? _contactEmail
                : (_userData['email']?.isEmpty ?? true
                    ? 'info@onboardsoft.com'
                    : _userData['email']!),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: allCellsLabelColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: EdgeInsets.zero,
        indicator: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Order Lines'),
          Tab(text: 'Other Info'),
          Tab(text: 'Payments'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    // Use IndexedStack to show only the current tab and size to its content
    // This allows dynamic height based on the content of each tab
    return Container(
      color: Colors.white,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: IndexedStack(
          index: _tabController.index,
          sizing: StackFit.loose, // Size to the current child
          children: [
            _buildOrderLinesTab(),
            _buildOtherInfoTab(),
            _buildPaymentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderLinesTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sticky Product Selection Section
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Product',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: allCellsLabelColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingProducts)
                  const Center(child: CircularProgressIndicator())
                else if (_getAvailableProducts().isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'All products have been added',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<ProductModel>(
                    key: ValueKey<int>(_dropdownKey),
                    value: null,
                    isExpanded: true, // Allow dropdown to use full width
                    decoration: InputDecoration(
                      hintText: 'Select a product *',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items:
                        _getAvailableProducts().map((ProductModel product) {
                          return DropdownMenuItem<ProductModel>(
                            value: product,
                            child: Text(
                              product.productTitle,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                    onChanged: _onProductSelectedForAdd,
                    validator: (value) {
                      if (_getAvailableProducts().isNotEmpty && value == null) {
                        return 'Please select a product';
                      }
                      return null;
                    },
                  ),
              ],
            ),
          ),
        ),
        // Products List with fixed height for scrolling
        if (_selectedProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please select a product from the dropdown above to add it to your order. You can add multiple products.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_selectedProducts.length, (index) {
            final item = _selectedProducts[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildProductCard(item, index),
            );
          }),
      ],
    );
  }

  Widget _buildProductCard(_OrderProductItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with product name and remove button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.product.productTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _removeProduct(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildProductInfoRow('SKU:', item.product.sku),
          const SizedBox(height: 6),
          _buildProductInfoRow(
            'PRICE:',
            NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 2,
            ).format(item.product.rate.toDouble()),
          ),
          const SizedBox(height: 8),
          // Quantity controls aligned to right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(item.total)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    onPressed: () {
                      if (item.quantity > 1) {
                        _updateProductQuantity(index, item.quantity - 1);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.quantity.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    onPressed: () {
                      _updateProductQuantity(index, item.quantity + 1);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: allCellsLabelColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order Title Section
          Text(
            'Order Title',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: allCellsLabelColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _orderTitleController,
            decoration: InputDecoration(
              hintText: 'Order - $_orderNumber',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Notes Section
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: allCellsLabelColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              // Dismiss keyboard when done is pressed
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              hintText: 'Enter notes...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment Methods
          if (_paymentDetails != null &&
              _paymentDetails!.paymentMethods.isNotEmpty) ...[
            // Iterate through all payment methods
            for (
              int i = 0;
              i < _paymentDetails!.paymentMethods.length;
              i++
            ) ...[
              if (i > 0) const SizedBox(height: 24),
              // Payment Method Title
              Text(
                _paymentDetails!.paymentMethods.length > 1
                    ? 'Payment Method ${i + 1}'
                    : 'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: allCellsLabelColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _paymentDetails!.paymentMethods[i].paymentMethod.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Bank Account Details
              if (_paymentDetails!.paymentMethods[i].paymentDetails.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Html(
                    data: _paymentDetails!.paymentMethods[i].paymentDetails,
                    shrinkWrap: true,
                    style: {
                      'p': Style(
                        margin: Margins.only(bottom: 8),
                        padding: HtmlPaddings.zero,
                      ),
                      'strong': Style(
                        fontWeight: FontWeight.bold,
                        color: allCellsLabelColor,
                      ),
                    },
                  ),
                ),
            ],
          ] else if (_selectedProducts.isEmpty) ...[
            // Show message if product not selected
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please select a product first to load payment details.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Show message if payment details not loaded
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment details are being loaded. Please wait...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          _buildSummaryRow('Subtotal:', _subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('Est. discount:', _discount),
          const SizedBox(height: 8),
          _buildSummaryRow('Est. shipping or delivery:', _shipping),
          const SizedBox(height: 8),
          _buildSummaryRow('Est. tax:', _tax),
          const Divider(height: 24),
          _buildSummaryRow('Grand Total:', _grandTotal, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: allCellsLabelColor,
          ),
        ),
        Text(
          NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount),
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _selectedProducts.isEmpty ? null : () => _handleSaveDraft(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Draft',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _selectedProducts.isEmpty ? null : () => _handleSubmitOrder(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Order',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateOrder() {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product to the order'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    // Validate all products have valid quantities
    for (var item in _selectedProducts) {
      if (item.quantity < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All products must have a quantity of at least 1'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }
    }

    if (_userData['email']?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact email is required'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }

  void _handleSaveDraft() {
    if (!_validateOrder()) return;

    _saveOrderAsDraft();
  }

  Future<void> _saveOrderAsDraft() async {
    if (_selectedProducts.isEmpty) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Build items_list JSON from all selected products
      final itemsList =
          _selectedProducts.map((item) {
            return {
              'id':
                  'row-${DateTime.now().millisecondsSinceEpoch}-${item.product.productId}',
              'data': {
                'id': item.product.productId,
                'sku': item.product.sku,
                'name': item.product.productTitle,
                'quantity': item.quantity,
                'unit': item.quantity.toString(),
                'price': item.product.rate.toStringAsFixed(4),
                'total': item.total.toStringAsFixed(2),
                'type': 'service',
                'description': _notesController.text,
              },
            };
          }).toList();
      final itemsListJson = jsonEncode(itemsList);

      // Get payment details HTML from first payment method
      final paymentDetailsHtml =
          _paymentDetails != null && _paymentDetails!.paymentMethods.isNotEmpty
              ? _paymentDetails!.paymentMethods[0].paymentDetails
              : '';

      // Get validity from payment settings or default
      final validity = _paymentDetails?.paymentSettings.validity ?? '90';

      // Save order as draft
      final success = await _salesOrdersService.saveOrderAsDraft(
        accountNo: _userData['accountno']!,
        orderNo: _orderNumber,
        contactEmail:
            _contactEmail.isNotEmpty
                ? _contactEmail
                : (_userData['email']?.isEmpty ?? true
                    ? 'info@onboardsoft.com'
                    : _userData['email']!),
        contactPerson:
            _contactPerson.isNotEmpty
                ? _contactPerson
                : (_userData['name']?.isEmpty ?? true
                    ? 'JAMES SMITH'
                    : _userData['name']!),
        currency: _currency.toLowerCase(),
        paymentTerms: _termsOfPayment,
        validity: validity,
        quoteTitle:
            _orderTitleController.text.isNotEmpty
                ? _orderTitleController.text
                : 'Order - $_orderNumber',
        quotationNotes: _notesController.text,
        itemsListJson: itemsListJson,
        paymentDetails: paymentDetailsHtml,
        serviceGrandSubTotal: _subtotal,
        serviceGrandTotal: _grandTotal,
        discountValue: _discount,
        discountValueTotal: _discount,
        discountType: 'amount',
        discountReason: '',
        shippingValue: _shipping > 0 ? _shipping.toStringAsFixed(2) : '',
        shippingValueTotal: _shipping,
        shippingTitle: '',
        taxValue: _tax,
        taxValueTotal: _tax,
        taxType: 'amount',
        taxReason: '',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order saved as draft successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save order as draft: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleSubmitOrder() {
    if (!_validateOrder()) return;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Text(
            'Are you sure you want to submit this order for ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(_grandTotal)}?',
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: const Size(70, 36),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _submitOrderToApi();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    backgroundColor: AppColors.primaryColor,
                    minimumSize: const Size(70, 36),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitOrderToApi() async {
    if (_selectedProducts.isEmpty) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Build items_list JSON from all selected products
      final itemsList =
          _selectedProducts.map((item) {
            return {
              'id':
                  'row-${DateTime.now().millisecondsSinceEpoch}-${item.product.productId}',
              'data': {
                'id': item.product.productId,
                'sku': item.product.sku,
                'name': item.product.productTitle,
                'quantity': item.quantity,
                'unit': item.quantity.toString(),
                'price': item.product.rate.toStringAsFixed(4),
                'total': item.total.toStringAsFixed(2),
                'type': 'service',
              },
            };
          }).toList();
      final itemsListJson = jsonEncode(itemsList);

      // Get payment details HTML from first payment method
      final paymentDetailsHtml =
          _paymentDetails != null && _paymentDetails!.paymentMethods.isNotEmpty
              ? _paymentDetails!.paymentMethods[0].paymentDetails
              : '';

      // Get validity from payment settings or default
      final validity = _paymentDetails?.paymentSettings.validity ?? '90';

      // Submit order
      final success = await _salesOrdersService.submitOrder(
        accountNo: _userData['accountno']!,
        orderNo: _orderNumber,
        contactEmail:
            _contactEmail.isNotEmpty
                ? _contactEmail
                : (_userData['email']?.isEmpty ?? true
                    ? ''
                    : _userData['email']!),
        contactPerson:
            _contactPerson.isNotEmpty
                ? _contactPerson
                : (_userData['name']?.isEmpty ?? true
                    ? ''
                    : _userData['name']!),
        currency: _currency.toLowerCase(),
        paymentTerms: _termsOfPayment,
        validity: validity,
        quoteTitle:
            _orderTitleController.text.isNotEmpty
                ? _orderTitleController.text
                : 'Order - $_orderNumber',
        quotationNotes: _notesController.text,
        itemsListJson: itemsListJson,
        paymentDetails: paymentDetailsHtml,
        serviceGrandSubTotal: _subtotal,
        serviceGrandTotal: _grandTotal,
        discountValue: _discount,
        discountValueTotal: _discount,
        discountType: 'amount',
        discountReason: '',
        shippingValue: _shipping,
        shippingValueTotal: _shipping,
        shippingTitle: '',
        taxValue: _tax,
        taxValueTotal: _tax,
        taxType: 'amount',
        taxReason: '',
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order submitted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Navigate back after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit order: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

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
import 'package:voicealerts_obs/features/orders/domain/models/order_details_model.dart';
import 'package:voicealerts_obs/features/orders/domain/models/payment_complete_details_model.dart';
import 'package:voicealerts_obs/features/products/domain/models/product_model.dart';

class CreateOrderScreen extends StatefulWidget {
  final ProductModel? product; // Optional for edit mode
  final OrderDetailsModel? orderDetails; // For edit mode

  const CreateOrderScreen({super.key, this.product, this.orderDetails})
    : assert(
        product != null || orderDetails != null,
        'Either product or orderDetails must be provided',
      );

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SalesOrdersService _salesOrdersService = SalesOrdersService();
  Map<String, String> _userData = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Order form data
  int _quantity = 1;
  double _unitPrice = 0.0;
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _shipping = 0.0;
  double _tax = 0.0;
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

      // Check if we're in edit mode
      if (widget.orderDetails != null) {
        // Edit mode: populate from existing order
        await _populateFromOrderDetails(widget.orderDetails!);
      } else {
        // Create mode: generate new order
        // Generate random order number (7 digits like "3625656")
        _orderNumber = _generateRandomOrderNumber();

        // Set issue date to today
        _issueDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

        // Initialize pricing from product
        if (widget.product != null) {
          _unitPrice = widget.product!.rate.toDouble();
          _calculateTotals();
        }

        // Initialize order title with order number
        _orderTitleController.text = 'Order - $_orderNumber';

        // Fetch payment details from API
        if (_userData['accountno']?.isNotEmpty ?? false) {
          await _fetchPaymentDetails();
        }
      }

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

  Future<void> _populateFromOrderDetails(OrderDetailsModel orderDetails) async {
    // Set order number (existing order)
    _orderNumber = orderDetails.orderNo;

    // Set issue date
    _issueDate = DateFormat('MMMM d, yyyy').format(orderDetails.dateCreated);

    // Populate order title
    _orderTitleController.text = orderDetails.quoteTitle;

    // Populate from first service (assuming single product for now)
    if (orderDetails.quoteServices.isNotEmpty) {
      final service = orderDetails.quoteServices[0];
      _quantity = service.quantity;
      _unitPrice = service.servicePrice;
      // Get notes from service description field
      _notesController.text = service.description;
      _calculateTotals();
    } else {
      // Fallback to quote_notes if no services
      _notesController.text = orderDetails.quoteNotes;
    }

    // Fetch payment details from API (this will populate payment settings and payment method)
    // This is the same API used when creating a new order
    if (_userData['accountno']?.isNotEmpty ?? false) {
      await _fetchPaymentDetails();
    } else {
      // If account number not available, use values from order details as fallback
      _termsOfPayment = orderDetails.paymentTerms;
      _currency = orderDetails.currency.toUpperCase();
      _contactPerson = orderDetails.contactPerson;
      _contactEmail = orderDetails.contactEmail;
    }
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

        // Parse HTML payment details
        _parsePaymentDetailsHtml(paymentDetails.paymentMethod.paymentDetails);
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
      _subtotal = _quantity * _unitPrice;
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
          title: Text(
            widget.orderDetails != null ? 'Edit Order' : 'Create Order',
          ),
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
        title: Text(
          widget.orderDetails != null ? 'Edit Order' : 'Create Order',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      color: Colors.white,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderLinesTab(),
          _buildOtherInfoTab(),
          _buildPaymentsTab(),
        ],
      ),
    );
  }

  Widget _buildOrderLinesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProductInfoCard(),
          const SizedBox(height: 16),
          _buildQuantityInput(),
        ],
      ),
    );
  }

  Widget _buildProductInfoCard() {
    // Get product info from product or orderDetails
    final productName =
        widget.product?.productTitle ??
        (widget.orderDetails?.quoteServices.isNotEmpty ?? false
            ? widget.orderDetails!.quoteServices[0].serviceName
            : '');
    final productId =
        widget.product?.productId ??
        (widget.orderDetails?.quoteServices.isNotEmpty ?? false
            ? widget.orderDetails!.quoteServices[0].serviceId
            : 0);
    final sku =
        widget.product?.sku ??
        (widget.orderDetails?.quoteServices.isNotEmpty ?? false
            ? widget.orderDetails!.quoteServices[0].sku
            : '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductInfoRow('PRODUCT NAME:', productName),
          const SizedBox(height: 8),
          _buildProductInfoRow('ITEM ID:', productId.toString()),
          const SizedBox(height: 8),
          _buildProductInfoRow('SKU:', sku),
          const SizedBox(height: 8),
          _buildProductInfoRow('QTY:', _quantity.toString()),
          const SizedBox(height: 8),
          _buildProductInfoRow('UNIT:', _quantity.toString()),
          const SizedBox(height: 8),
          _buildProductInfoRow(
            'PRICE (\$):',
            NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 2,
            ).format(_unitPrice),
          ),
          const SizedBox(height: 8),
          _buildProductInfoRow(
            'TOTAL (\$):',
            NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 2,
            ).format(_subtotal),
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

  Widget _buildQuantityInput() {
    return Row(
      children: [
        const Text(
          'Quantity:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () {
            if (_quantity > 1) {
              setState(() {
                _quantity--;
                _calculateTotals();
              });
            }
          },
        ),
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _quantity.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            setState(() {
              _quantity++;
              _calculateTotals();
            });
          },
        ),
      ],
    );
  }

  Widget _buildOtherInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Method Title
          if (_paymentDetails != null) ...[
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: allCellsLabelColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _paymentDetails!.paymentMethod.paymentMethod.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Bank Account Details Title
          Text(
            'Bank Account Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: allCellsLabelColor,
            ),
          ),
          const SizedBox(height: 16),
          // Show parsed bank details or HTML content
          if (_paymentDetails != null &&
              _paymentDetails!.paymentMethod.paymentDetails.isNotEmpty) ...[
            // Show HTML content if available
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Html(
                data: _paymentDetails!.paymentMethod.paymentDetails,
                style: {
                  'p': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                  'strong': Style(
                    fontWeight: FontWeight.bold,
                    color: allCellsLabelColor,
                  ),
                },
              ),
            ),
          ] else ...[
            // Fallback to parsed data if HTML parsing failed or not available
            _buildBankInfoRow(
              'Bank Name:',
              _bankAccountData['bankName']?.isEmpty ?? true
                  ? 'N/A'
                  : _bankAccountData['bankName']!,
            ),
            const SizedBox(height: 12),
            _buildBankInfoRow(
              'Account Holder Name:',
              _bankAccountData['accountHolderName']?.isEmpty ?? true
                  ? 'N/A'
                  : _bankAccountData['accountHolderName']!,
            ),
            const SizedBox(height: 12),
            _buildBankInfoRow(
              'Account Number:',
              _bankAccountData['accountNumber']?.isEmpty ?? true
                  ? 'N/A'
                  : _bankAccountData['accountNumber']!,
            ),
            const SizedBox(height: 12),
            _buildBankInfoRow(
              'Bank Address:',
              _bankAccountData['bankAddress']?.isEmpty ?? true
                  ? 'N/A'
                  : _bankAccountData['bankAddress']!,
            ),
            const SizedBox(height: 12),
            _buildBankInfoRow(
              'Routing Number:',
              _bankAccountData['routingNumber']?.isEmpty ?? true
                  ? 'N/A'
                  : _bankAccountData['routingNumber']!,
            ),
            const SizedBox(height: 12),
            _buildBankInfoRow(
              'SWIFT CODE:',
              _bankAccountData['swiftCode']?.isEmpty ?? true
                  ? 'N/A'
                  : _bankAccountData['swiftCode']!,
            ),
            const SizedBox(height: 12),
            _buildBankInfoRow(
              'IBAN:',
              _bankAccountData['iban']?.isEmpty ?? true
                  ? 'N/A'
                  : _bankAccountData['iban']!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
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
              onPressed: () => _handleSaveDraft(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Draft',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleSubmitOrder(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateOrder() {
    if (_quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity must be at least 1'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    if (_unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid product price'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return false;
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
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Build items_list JSON (same as submit, but can include description)
      // Get product info from product or orderDetails
      final productId =
          widget.product?.productId ??
          (widget.orderDetails?.quoteServices.isNotEmpty ?? false
              ? widget.orderDetails!.quoteServices[0].serviceId
              : 0);
      final sku =
          widget.product?.sku ??
          (widget.orderDetails?.quoteServices.isNotEmpty ?? false
              ? widget.orderDetails!.quoteServices[0].sku
              : '');
      final productName =
          widget.product?.productTitle ??
          (widget.orderDetails?.quoteServices.isNotEmpty ?? false
              ? widget.orderDetails!.quoteServices[0].serviceName
              : '');

      final itemsList = [
        {
          'id': 'row-${DateTime.now().millisecondsSinceEpoch}',
          'data': {
            'id': productId,
            'sku': sku,
            'name': productName,
            'quantity': _quantity,
            'unit': _quantity.toString(),
            'price': _unitPrice.toStringAsFixed(4),
            'total': _subtotal.toStringAsFixed(2),
            'type': 'service', // Database column only accepts 'service'
            'description': _notesController.text, // Optional description
          },
        },
      ];
      final itemsListJson = jsonEncode(itemsList);

      // Get payment details HTML
      final paymentDetailsHtml =
          _paymentDetails?.paymentMethod.paymentDetails ?? '';

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
          content: Text(
            'Are you sure you want to submit this order for ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(_grandTotal)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitOrderToApi();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitOrderToApi() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Build items_list JSON
      // Get product info from product or orderDetails
      final productId =
          widget.product?.productId ??
          (widget.orderDetails?.quoteServices.isNotEmpty ?? false
              ? widget.orderDetails!.quoteServices[0].serviceId
              : 0);
      final sku =
          widget.product?.sku ??
          (widget.orderDetails?.quoteServices.isNotEmpty ?? false
              ? widget.orderDetails!.quoteServices[0].sku
              : '');
      final productName =
          widget.product?.productTitle ??
          (widget.orderDetails?.quoteServices.isNotEmpty ?? false
              ? widget.orderDetails!.quoteServices[0].serviceName
              : '');

      final itemsList = [
        {
          'id': 'row-${DateTime.now().millisecondsSinceEpoch}',
          'data': {
            'id': productId,
            'sku': sku,
            'name': productName,
            'quantity': _quantity,
            'unit': _quantity.toString(),
            'price': _unitPrice.toStringAsFixed(4),
            'total': _subtotal.toStringAsFixed(2),
            'type': 'service', // Database column only accepts 'service'
          },
        },
      ];
      final itemsListJson = jsonEncode(itemsList);

      // Get payment details HTML
      final paymentDetailsHtml =
          _paymentDetails?.paymentMethod.paymentDetails ?? '';

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

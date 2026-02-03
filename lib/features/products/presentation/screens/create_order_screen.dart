import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/shared_prefence_keys.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/products/domain/models/product_model.dart';

class CreateOrderScreen extends StatefulWidget {
  final ProductModel product;

  const CreateOrderScreen({super.key, required this.product});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String> _userData = {};
  bool _isLoading = true;

  // Order form data
  int _quantity = 1;
  double _unitPrice = 0.0;
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _shipping = 0.0;
  double _tax = 0.0;
  double _grandTotal = 0.0;

  // Mock order data
  String _orderNumber = '';
  String _issueDate = '';
  String _termsOfPayment = 'Net 60';
  String _currency = 'USD';

  // Form controllers
  final TextEditingController _orderTitleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Mock bank account data
  final Map<String, String> _bankAccountData = {
    'bankName': 'My Bank',
    'accountHolderName': 'James Smith',
    'accountNumber': 'XXXXXXXXX',
    'bankAddress': '123 main street, City, Country',
    'routingNumber': '(For Certain Countries)',
    'swiftCode': '(For international transactions)',
    'iban': '(For international in Europe transactions)',
  };

  final orderCellColor = HexColor('#F3F3F3');
  final allCellsLabelColor = HexColor('#02274D');
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _initializeOrderData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userData = {
          'comp_name':
              prefs.getString(SharedPreferenceKeys.companyNameKey) ?? '',
          'name': prefs.getString(SharedPreferenceKeys.nameKey) ?? '',
          'email': prefs.getString(SharedPreferenceKeys.emailKey) ?? '',
          'accountno': prefs.getString(SharedPreferenceKeys.accountNoKey) ?? '',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeOrderData() {
    // Generate mock order number
    _orderNumber = DateTime.now().millisecondsSinceEpoch.toString().substring(
      5,
    );

    // Set issue date to today
    _issueDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

    // Initialize pricing from product
    _unitPrice = widget.product.rate.toDouble();
    _calculateTotals();

    // Initialize order title with order number
    _orderTitleController.text = 'Order - $_orderNumber';
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
        appBar: AppBar(title: const Text('Create Order')),
        body: const Center(child: CircularProgressIndicator()),
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
            _userData['name']?.isEmpty ?? true
                ? 'JAMES SMITH'
                : _userData['name']!.toUpperCase(),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'EMAIL:',
            _userData['email']?.isEmpty ?? true
                ? 'info@onboardsoft.com'
                : _userData['email']!,
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
          _buildProductInfoRow('PRODUCT NAME:', widget.product.productTitle),
          const SizedBox(height: 8),
          _buildProductInfoRow('ITEM ID:', widget.product.productId.toString()),
          const SizedBox(height: 8),
          _buildProductInfoRow('SKU:', widget.product.sku),
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
          // Bank Information
          _buildBankInfoRow('Bank Name:', _bankAccountData['bankName']!),
          const SizedBox(height: 12),
          _buildBankInfoRow(
            'Account Holder Name:',
            _bankAccountData['accountHolderName']!,
          ),
          const SizedBox(height: 12),
          _buildBankInfoRow(
            'Account Number:',
            _bankAccountData['accountNumber']!,
          ),
          const SizedBox(height: 12),
          _buildBankInfoRow('Bank Address:', _bankAccountData['bankAddress']!),
          const SizedBox(height: 12),
          _buildBankInfoRow(
            'Routing Number:',
            _bankAccountData['routingNumber']!,
          ),
          const SizedBox(height: 12),
          _buildBankInfoRow('SWIFT CODE:', _bankAccountData['swiftCode']!),
          const SizedBox(height: 12),
          _buildBankInfoRow('IBAN:', _bankAccountData['iban']!),
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

    // TODO: Implement save as draft API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order saved as draft'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
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
                // TODO: Implement submit order API
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order submitted successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                // Optionally navigate back
                // Navigator.of(context).pop();
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
}

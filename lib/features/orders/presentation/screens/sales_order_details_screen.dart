import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:voicealerts_obs/core/constants/shared_prefence_keys.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custome_pdf_viewer.dart';
import 'package:voicealerts_obs/features/orders/data/services/sales_orders_service.dart';
import 'package:voicealerts_obs/features/orders/domain/models/sales_order_model.dart';
import 'package:voicealerts_obs/features/orders/domain/models/sales_order_view_details_model.dart';

class SalesOrderDetailsScreen extends StatefulWidget {
  final SalesOrderModel order;

  const SalesOrderDetailsScreen({super.key, required this.order});

  @override
  State<SalesOrderDetailsScreen> createState() =>
      _SalesOrderDetailsScreenState();
}

class _SalesOrderDetailsScreenState extends State<SalesOrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SalesOrdersService _salesOrdersService = SalesOrdersService();

  bool _isLoading = true;
  String? _errorMessage;
  SalesOrderViewDetailsModel? _viewDetails;

  final orderCellColor = HexColor('#F3F3F3');
  final allCellsLabelColor = HexColor('#02274D');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accountNo =
          prefs.getString(SharedPreferenceKeys.accountNoKey) ?? '';

      if (accountNo.isEmpty) {
        throw Exception('Account number not found');
      }

      final details = await _salesOrdersService.getSalesOrderViewDetails(
        accountNo: accountNo,
        orderNo: widget.order.orderNo,
      );
      if (mounted) {
        setState(() {
          _viewDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load order details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Something went wrong. Please try again.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: _fetchOrderDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No order details available')),
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
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildOrderDetailsSection(),
                    _buildTabs(),
                    _buildTabContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    final orderDetails = _viewDetails!.orderDetails;
    final paymentSettings = _viewDetails!.paymentDetails.paymentSettings;

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
          _buildInfoRow('ORDER NUMBER:', orderDetails.orderNo),
          const SizedBox(height: 8),
          _buildInfoRow(
            'ISSUE DATE:',
            DateFormat('MMMM d, yyyy').format(orderDetails.dateCreated),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('FROM:', 'OnBoardSoft LLC'),
          const SizedBox(height: 8),
          _buildInfoRow('COMPANY:', orderDetails.clientAccountNo),
          const SizedBox(height: 8),
          _buildInfoRow('TERMS OF PAYMENT:', paymentSettings.paymentTerms),
          const SizedBox(height: 8),
          _buildInfoRow('CURRENCY:', paymentSettings.currency.toUpperCase()),
          const SizedBox(height: 8),
          _buildInfoRow(
            'CONTACT PERSON:',
            paymentSettings.contactPerson.toUpperCase(),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('EMAIL:', paymentSettings.contactEmail),
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
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Order Summary'),
          Tab(text: 'Payments'),
          Tab(text: 'Payment Logs'),
          Tab(text: 'Comments'),
          Tab(text: 'Order Documents'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      color: Colors.white,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderSummaryTab(),
          _buildPaymentsTab(),
          _buildPaymentLogsTab(),
          _buildCommentsTab(),
          _buildOrderDocumentsTab(),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryTab() {
    final orderDetails = _viewDetails!.orderDetails;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Order Title
        Text(
          'Order Title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: allCellsLabelColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            orderDetails.quoteTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Products/Services
        Text(
          'Products/Services',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: allCellsLabelColor,
          ),
        ),
        const SizedBox(height: 12),

        // List all services
        ...orderDetails.quoteServices.map((service) {
          final subtotal = service.quantity * service.servicePrice;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfoRow('PRODUCT NAME:', service.serviceName),
                const SizedBox(height: 8),
                _buildProductInfoRow('SKU:', service.sku),
                const SizedBox(height: 8),
                _buildProductInfoRow('QTY:', service.quantity.toString()),
                const SizedBox(height: 8),
                _buildProductInfoRow(
                  'PRICE (\$):',
                  NumberFormat.currency(
                    symbol: '\$',
                    decimalDigits: 2,
                  ).format(service.servicePrice),
                ),
                const SizedBox(height: 8),
                _buildProductInfoRow(
                  'TOTAL (\$):',
                  NumberFormat.currency(
                    symbol: '\$',
                    decimalDigits: 2,
                  ).format(subtotal),
                ),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildProductInfoRow('DESCRIPTION:', service.description),
                ],
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 24),

        // Order Notes
        if (orderDetails.quoteNotes.isNotEmpty) ...[
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: allCellsLabelColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              orderDetails.quoteNotes,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Summary Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
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
              _buildSummaryRow('Subtotal:', _calculateSubtotal()),
              const SizedBox(height: 8),
              _buildSummaryRow('Est. discount:', 0.0),
              const SizedBox(height: 8),
              _buildSummaryRow('Est. shipping or delivery:', 0.0),
              const SizedBox(height: 8),
              _buildSummaryRow('Est. tax:', 0.0),
              const Divider(height: 24),
              _buildSummaryRow(
                'Grand Total:',
                _calculateSubtotal(),
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
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

  double _calculateSubtotal() {
    return _viewDetails!.orderDetails.quoteServices.fold(
      0.0,
      (sum, service) => sum + (service.quantity * service.servicePrice),
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

  Widget _buildPaymentsTab() {
    final paymentMethods = _viewDetails!.paymentDetails.paymentMethods;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Payment Methods
        if (paymentMethods.isNotEmpty) ...[
          // Iterate through all payment methods
          for (int i = 0; i < paymentMethods.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            // Payment Method Title
            Text(
              paymentMethods.length > 1
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
              paymentMethods[i].paymentMethod.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Bank Account Details from HTML
            if (paymentMethods[i].paymentDetails.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Html(
                  data: paymentMethods[i].paymentDetails,
                  style: {
                    'p': Style(
                      margin: Margins.zero,
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
        ] else ...[
          Center(
            child: Text(
              'No payment methods available',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentLogsTab() {
    final hasPaymentLogs = _viewDetails!.hasPaymentLogs;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Payment Logs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: allCellsLabelColor,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                hasPaymentLogs
                    ? 'Payment logs feature coming soon'
                    : 'No payment logs available',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTab() {
    final comments = _viewDetails!.comments;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Comments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: allCellsLabelColor,
          ),
        ),
        const SizedBox(height: 16),

        // Comments List
        if (comments.isNotEmpty) ...[
          ...comments.map((comment) => _buildCommentCard(comment)).toList(),
        ] else ...[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No comments yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentCard(comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  comment.fromType,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.fromName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM d, yyyy').format(comment.dateAdded),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.conversation,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDocumentsTab() {
    final orderDetails = _viewDetails!.orderDetails;
    final documents = _viewDetails!.documents;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header with Upload Button
        Row(
          children: [
            Expanded(
              child: Text(
                'Order Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: allCellsLabelColor,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _showUploadDocumentDialog,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // // Main Order PDF
        // if (orderDetails.quoteAttachment.isNotEmpty) ...[
        //   _buildDocumentCard(
        //     title: 'Order PDF',
        //     filename:'https://dev-agents.onboardsoft.me/files_data/orders/${orderDetails.quoteAttachment}',
        //     date: DateFormat('MMM d, yyyy').format(orderDetails.dateCreated),
        //   ),
        //   const SizedBox(height: 12),
        // ],

        // Additional Uploaded Documents
        if (documents.isNotEmpty) ...[
          ...documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDocumentCard(
                title: doc.documentName,
                filename: doc.documentPath,
                date: DateFormat('MMM d, yyyy').format(doc.dateUploaded),
              ),
            ),
          ),
        ],

        // Empty state
        if (orderDetails.quoteAttachment.isEmpty && documents.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents available',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String filename,
    required String date,
  }) {
    // Determine file type and icon from filename/URL
    final String extension = filename.toLowerCase().split('.').last;
    IconData fileIcon;
    Color iconColor;

    if (extension.contains('pdf')) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (extension.contains('jpg') ||
        extension.contains('jpeg') ||
        extension.contains('png') ||
        extension.contains('gif') ||
        extension.contains('webp')) {
      fileIcon = Icons.image;
      iconColor = Colors.blue;
    } else if (extension.contains('doc') || extension.contains('docx')) {
      fileIcon = Icons.description;
      iconColor = Colors.blue.shade700;
    } else if (extension.contains('xls') || extension.contains('xlsx')) {
      fileIcon = Icons.table_chart;
      iconColor = Colors.green.shade700;
    } else if (extension.contains('zip') || extension.contains('rar')) {
      fileIcon = Icons.folder_zip;
      iconColor = Colors.orange;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // File Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(fileIcon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),

          // Document Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // View Button
          IconButton(
            onPressed: () => _viewDocument(filename, title),
            icon: Icon(
              Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  Future<void> _viewDocument(String documentUrl, String title) async {
    if (documentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Build full URL if needed
    String fullUrl = documentUrl;
    if (!documentUrl.startsWith('http://') &&
        !documentUrl.startsWith('https://')) {
      // If it's a relative path, build the full URL
      fullUrl = 'https://dev-agents.onboardsoft.me/$documentUrl';
    }

    // Get file extension
    final String extension = fullUrl.toLowerCase().split('.').last;

    // Check if it's a PDF
    if (extension.contains('pdf')) {
      // Navigate to PDF viewer
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomPdfViewer(url: fullUrl, title: title),
        ),
      );
    } else if (extension.contains('jpg') ||
        extension.contains('jpeg') ||
        extension.contains('png') ||
        extension.contains('gif') ||
        extension.contains('webp')) {
      // For images, show in a full screen viewer
      _showImageViewer(fullUrl, title);
    } else {
      // For other file types, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot preview $extension files. Download to view.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showImageViewer(String imageUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Failed to load image'),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _showUploadDocumentDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.insert_drive_file,
                  color: AppColors.primaryColor,
                ),
                title: const Text('Choose File'),
                subtitle: const Text('PDF, Images, Documents'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickAndUploadFile();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'zip',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final filePath = file.path!;
        final fileName = file.name;

        // Show document title input dialog
        if (!mounted) return;
        final documentTitle = await _showDocumentTitleDialog(fileName);

        if (documentTitle == null || documentTitle.isEmpty) {
          // User cancelled or didn't enter a title
          return;
        }

        // Show loading indicator
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        // Upload file to server
        final response = await _salesOrdersService.uploadOrderDocument(
          orderNo: widget.order.orderNo,
          filePath: filePath,
          fileName: fileName,
          documentTitle: documentTitle,
        );

        // Close loading
        if (!mounted) return;
        Navigator.of(context).pop();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Document uploaded successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the order details
        await _fetchOrderDetails();
      }
    } catch (e) {
      // Close loading if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showDocumentTitleDialog(String defaultFileName) async {
    final TextEditingController controller = TextEditingController(
      text: defaultFileName.split('.').first, // Remove extension
    );

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Document Title'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Enter document title',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );
  }
}

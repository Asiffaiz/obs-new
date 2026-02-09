import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/core/widgets/custome_pdf_viewer.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import 'package:voicealerts_obs/features/orders/data/services/sales_orders_service.dart';
import 'package:voicealerts_obs/features/orders/domain/models/sales_order_model.dart';
import 'package:voicealerts_obs/features/orders/presentation/bloc/sales_orders_bloc.dart';
import 'package:voicealerts_obs/features/orders/presentation/bloc/sales_orders_event.dart';
import 'package:voicealerts_obs/features/orders/presentation/bloc/sales_orders_state.dart';
import 'package:voicealerts_obs/features/orders/presentation/screens/create_order_from_orders_screen.dart';
import 'package:voicealerts_obs/features/orders/presentation/screens/sales_order_details_screen.dart';
import 'package:voicealerts_obs/features/products/presentation/screens/create_order_screen.dart';

class SalesOrdersScreen extends StatefulWidget {
  const SalesOrdersScreen({super.key});

  @override
  State<SalesOrdersScreen> createState() => _SalesOrdersScreenState();
}

class _SalesOrdersScreenState extends State<SalesOrdersScreen> {
  final SalesOrdersService _salesOrdersService = SalesOrdersService();

  @override
  void initState() {
    super.initState();
    context.read<SalesOrdersBloc>().add(const LoadSalesOrders());
  }

  final orderCellColor = HexColor('#F3F3F3');
  final allCellsLabelColor = HexColor('#02274D');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Orders'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateOrderFromOrdersScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<SalesOrdersBloc, SalesOrdersState>(
        listener: (context, state) {
          if (state.status == SalesOrdersStatus.error &&
              state.errorMessage != null) {
            CustomErrorDialog.show(
              context: context,
              onRetry: () {
                Navigator.pop(context);
                context.read<SalesOrdersBloc>().add(const LoadSalesOrders());
              },
            );
          }
        },
        builder: (context, state) {
          if (state.status == SalesOrdersStatus.loading) {
            return const DashboardShimmer();
          }

          if (state.status == SalesOrdersStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load sales orders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Something went wrong. Please try again.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<SalesOrdersBloc>().add(
                        const LoadSalesOrders(),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.salesOrders.isEmpty) {
            return const Center(
              child: Text(
                'No sales orders available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SalesOrdersBloc>().add(const LoadSalesOrders());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.salesOrders.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildOrderCard(state.salesOrders[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(SalesOrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.agreementCardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleOrderTap(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Order Number and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      'Order #',
                      order.orderNo,
                      valueStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    onSelected: (value) {
                      if (value == 'view_details') {
                        _handleViewDetails(order);
                      } else if (value == 'edit_order') {
                        _handleEditOrder(order);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'view_details',
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 20,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (order.isPending)
                          PopupMenuItem<String>(
                            value: 'edit_order',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Edit Order',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ];
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quotation Number Row
              if (order.quoteAccountNo != null) ...[
                _buildInfoRow('Quotation #', order.quoteAccountNo!),
                const SizedBox(height: 12),
              ],
              // Date Created Row
              _buildInfoRow(
                'Date Created',
                DateFormat('MMMM d, yyyy').format(order.dateCreated),
              ),
              const SizedBox(height: 12),
              // Attachment Row with Label
              _buildAttachmentRow(order),
              const SizedBox(height: 12),
              // Status Row with Label
              _buildStatusRow(order),
              const SizedBox(height: 12),
              // Payment Status Row with Label
              _buildPaymentStatusRow(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: Adjust label width based on screen size
        final labelWidth = constraints.maxWidth < 400 ? 100.0 : 120.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: allCellsLabelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style:
                    valueStyle ??
                    const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(SalesOrderModel order) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = constraints.maxWidth < 400 ? 100.0 : 120.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                'Attachment',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: allCellsLabelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleViewAttachment(order),
                icon: const Icon(Icons.description, size: 16),
                label: const Text('View Attachment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(SalesOrderModel order) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = constraints.maxWidth < 400 ? 100.0 : 120.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                'Status',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: allCellsLabelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(
              order.isCompleted ? 'Completed' : 'Pending',
              order.isCompleted ? Colors.green : Colors.orange,
              order.isCompleted ? Icons.check : Icons.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentStatusRow(SalesOrderModel order) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = constraints.maxWidth < 400 ? 100.0 : 120.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                'Payment Status',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: allCellsLabelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(
              order.isPaid ? 'Paid' : 'Unpaid',
              order.isPaid ? Colors.green : Colors.red,
              order.isPaid ? Icons.check : Icons.warning,
            ),
          ],
        );
      },
    );
  }

  void _handleOrderTap(SalesOrderModel order) {
    _handleViewDetails(order);
  }

  void _handleViewAttachment(SalesOrderModel order) {
    if (order.quoteAttachment.isNotEmpty) {
      // Construct full URL for attachment
      String fullUrl = order.quoteAttachment;
      if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
        // Assuming base URL for attachments - adjust as needed
        fullUrl =
            'https://dev-agents.onboardsoft.me/files_data/orders/$fullUrl';
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  CustomPdfViewer(url: fullUrl, title: order.quoteTitle),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attachment not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleViewDetails(SalesOrderModel order) {
    // Navigate to SalesOrderDetailsScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesOrderDetailsScreen(order: order),
      ),
    );
  }

  Future<void> _handleEditOrder(SalesOrderModel order) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get account number
      final accountNo = await _salesOrdersService.getAccountNo();
      if (accountNo.isEmpty) {
        throw Exception('Account number not found');
      }

      // Fetch order details
      final orderDetails = await _salesOrdersService.getSingleSalesOrder(
        accountNo: accountNo,
        orderNo: order.orderNo,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to CreateOrderScreen in edit mode
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderScreen(orderDetails: orderDetails),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to load order details. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

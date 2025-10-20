import 'package:flutter/material.dart';
import '../../domain/models/agreement_model.dart';
import '../../../../core/theme/app_colors.dart';

class AgreementCard extends StatelessWidget {
  final AgreementModel agreement;
  final VoidCallback? onTap;

  const AgreementCard({super.key, required this.agreement, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // side: BorderSide(color: _getBorderColor(), width: 1),
        side: BorderSide(color: AppColors.primaryColor, width: 1),
      ),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      agreement.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                agreement.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTypeChip(),
                  if (agreement.isMandatory)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Required',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (agreement.status) {
      case AgreementStatus.signed:
        color = Colors.green;
        text = 'Signed';
        break;
      case AgreementStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case AgreementStatus.approved:
        color = Colors.blue;
        text = 'Approved';
        break;
      case AgreementStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    IconData iconData;
    String typeText;

    iconData = Icons.article;
    typeText = 'Document';

    return Row(
      children: [
        Icon(iconData, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          typeText,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Color _getBorderColor() {
    switch (agreement.status) {
      case AgreementStatus.signed:
        return Colors.green.shade300;
      case AgreementStatus.pending:
        return Colors.orange.shade300;
      case AgreementStatus.approved:
        return Colors.blue.shade300;
      case AgreementStatus.rejected:
        return Colors.red.shade300;
      default:
        return Colors.grey.shade300;
    }
  }
}

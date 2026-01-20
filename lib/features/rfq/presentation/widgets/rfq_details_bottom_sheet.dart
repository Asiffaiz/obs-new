import 'package:flutter/material.dart';
import 'package:voicealerts_obs/core/constants/breakpoints.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/rfq/data/services/rfq_service.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_detail_model.dart';

/// Bottom sheet to display RFQ details
class RfqDetailsBottomSheet extends StatefulWidget {
  final String rfqAccountNo;

  const RfqDetailsBottomSheet({
    super.key,
    required this.rfqAccountNo,
  });

  static Future<void> show(BuildContext context, String rfqAccountNo) {
    final isTablet = MediaQuery.of(context).size.width >= Breakpoints.tablet;
    
    if (isTablet) {
      // Show as dialog on tablet
      return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 50),
          child: RfqDetailsBottomSheet(rfqAccountNo: rfqAccountNo),
        ),
      );
    } else {
      // Show as bottom sheet on mobile
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RfqDetailsBottomSheet(rfqAccountNo: rfqAccountNo),
      );
    }
  }

  @override
  State<RfqDetailsBottomSheet> createState() => _RfqDetailsBottomSheetState();
}

class _RfqDetailsBottomSheetState extends State<RfqDetailsBottomSheet> {
  final RfqService _rfqService = RfqService();
  RfqDetail? _rfqDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRfqDetails();
  }

  Future<void> _loadRfqDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final detail = await _rfqService.getSingleRfq(widget.rfqAccountNo);
      
      setState(() {
        _rfqDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= Breakpoints.tablet;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: isTablet ? screenHeight * 0.85 : screenHeight * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isTablet ? const Radius.circular(20) : Radius.zero,
          bottomRight: isTablet ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context, isTablet),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildContent(context, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Text(
            'RFQ Details',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(
              'Failed to load RFQ details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again later',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRfqDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isTablet) {
    if (_rfqDetail == null) return const SizedBox();

    final groupedQuestions = _rfqDetail!.groupedQuestions;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 20,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Additional Information section (if rfq_comments exists)
          if (_rfqDetail!.rfqComments != null &&
              _rfqDetail!.rfqComments!.isNotEmpty) ...[
            _buildSection(
              context,
              'Additional Information',
              [
                _buildInfoRow(
                  'Description',
                  _rfqDetail!.rfqComments!,
                ),
              ],
              isTablet,
            ),
            const SizedBox(height: 24),
          ],

          // Questions grouped by sections
          ...groupedQuestions.entries.map((entry) {
            final groupTitle = entry.key;
            final questions = entry.value;

            // Filter out label and simple_text questions (they don't have answers)
            final answerableQuestions = questions.where((q) {
              return q.questionType != 'label' &&
                  q.questionType != 'simple_text' &&
                  q.getParsedAnswer(_rfqDetail!.allAnswers) != null;
            }).toList();

            if (answerableQuestions.isEmpty) {
              // If only labels/simple_text, show them as description
              final labelQuestions = questions
                  .where((q) => q.questionType == 'label' ||
                      q.questionType == 'simple_text')
                  .toList();
              
              if (labelQuestions.isNotEmpty) {
                final labelText = labelQuestions
                    .map((q) => _parseHtmlText(q.answerId))
                    .where((text) => text.isNotEmpty)
                    .join('\n');
                
                if (labelText.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildSection(
                      context,
                      groupTitle,
                      [
                        _buildInfoRow('Description', labelText),
                      ],
                      isTablet,
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildSection(
                context,
                groupTitle,
                answerableQuestions.map((question) {
                  final answer = question.getParsedAnswer(_rfqDetail!.allAnswers);
                  return _buildQuestionAnswerRow(
                    question.question,
                    answer ?? '—',
                    isTablet,
                  );
                }).toList(),
                isTablet,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Questions/Answers table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Question',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'Answer',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Table rows
              ...children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                final isLast = index == children.length - 1;
                
                return Column(
                  children: [
                    child,
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionAnswerRow(String question, String answer, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              question,
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey.shade300,
          ),
          Expanded(
            flex: 3,
            child: Text(
              answer,
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey.shade300,
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _parseHtmlText(String htmlText) {
    if (htmlText.isEmpty) return '';
    
    // Remove HTML tags
    try {
      // Check if it's HTML
      if (htmlText.contains('<')) {
        // Simple HTML tag removal
        return htmlText
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .trim();
      }
      return htmlText;
    } catch (e) {
      return htmlText;
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/features/agreements/presentation/screens/optional_agreements_wrapper_screen.dart';
import 'package:voicealerts_obs/features/agreements/presentation/screens/signed_agreements_main_screen.dart';
import 'package:voicealerts_obs/features/dashboard/domain/models/dashboard_data_model.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/bloc/bloc/dashboard_bloc.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import 'package:voicealerts_obs/features/forms/presentation/screens/form_main_screen.dart';
import 'package:voicealerts_obs/features/forms/presentation/screens/form_submissions_screen.dart';

import '../../../../core/theme/app_colors.dart';

class DashboardHomeContent extends StatefulWidget {
  final Function(String menuId, String? url)? onMenuItemSelected;

  const DashboardHomeContent({super.key, this.onMenuItemSelected});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> {
  @override
  void initState() {
    super.initState();
    // Only load data if it's not already loaded
    final currentState = context.read<DashboardBloc>().state;
    if (currentState is! DashboardLoaded) {
      context.read<DashboardBloc>().add(LoadDashboardData());
    }
  }

  _handleRetry() {
    context.read<DashboardBloc>().add(LoadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is DashboardError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            CustomErrorDialog.show(
              context: context,
              onRetry: () {
                // Your retry logic here
                Navigator.pop(context);
                _handleRetry();
              },
            );
          });
        }
      },
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const DashboardShimmer();
        }

        if (state is DashboardLoaded) {
          final dashboardData = state.dashboardData;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(LoadDashboardData());
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 16,
                  //     vertical: 8,
                  //   ),
                  //   child: _buildStatisticsCards(dashboardData),
                  // ),
                  _buildAssignedFormsList(dashboardData),

                  // _buildCleanNumberRequestCard(),
                  // _buildLetterOfAuthorizationCard(),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  _buildAssignedFormsList(DashboardDataModel dashboardData) {
    return dashboardData.assignedForms.isEmpty
        ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Html(data: dashboardData.welcomeContent),
        )
        : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: dashboardData.assignedForms.length,
          itemBuilder: (context, index) {
            final form = dashboardData.assignedForms[index];
            return _buildFormsCard(form);
          },
        );
  }

  // Keeping this method for potential future use
  // Widget _buildAgreementsCard() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     child: Card(
  //       elevation: 0,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         side: BorderSide(color: Colors.grey.shade300),
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.description_outlined,
  //                   color: AppColors.primaryColor,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 const Text(
  //                   'Agreements',
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 16),
  //             Container(
  //               decoration: BoxDecoration(
  //                 border: Border.all(color: Colors.grey.shade300),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Row(
  //                 children: [
  //                   Expanded(
  //                     child: _buildAgreementTab(
  //                       label: 'Signed',
  //                       count: '12',
  //                       isActive: true,
  //                     ),
  //                   ),
  //                   Expanded(
  //                     child: _buildAgreementTab(
  //                       label: 'Unsigned',
  //                       count: '12',
  //                       isActive: false,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatisticsCards(DashboardDataModel dashboardData) {
    final agreementSummary = dashboardData.agreementSummary;
    return Column(
      children: [
        _buildStatCard('Agreements', [
          StatItem('Signed', agreementSummary.totalSigned.toString()),
          StatItem('Unsigned', agreementSummary.totalNotSigned.toString()),
          StatItem('Archived', agreementSummary.totalAgreements.toString()),
        ], AppColors.dashboardCardColor),
      ],
    );
  }

  Widget _buildStatCard(String title, List<StatItem> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dashboarSummaryCardBorderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconForTitle(title), color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.welcomeMenuTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.map((item) => _buildStatItem(item)).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Agreements':
        return Icons.description_outlined;
      case 'Orders':
        return Icons.shopping_cart_outlined;
      case 'Commissions':
        return Icons.attach_money;
      case 'Sales':
        return Icons.trending_up;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildStatItem(StatItem item) {
    return InkWell(
      onTap: () {
        if (item.label == 'Unsigned') {
          // Navigate to agreement detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OptionalAgreementsWrapperScreen(),
            ),
          );
        } else {
          // Navigate to agreement detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SignedAgreementsMainScreen(
                    tabSelected: item.label == 'Signed' ? 0 : 1,
                  ),
            ),
          );
        }
      },
      child: Row(
        children: [
          Text(
            item.label,
            style: TextStyle(
              color: AppColors.welcomeMenuTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            item.value,
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementTab({
    required String label,
    required String count,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.appButtonColor : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$label $count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  String removeHtmlTags(String htmlString) {
    final RegExp exp = RegExp(
      r'<[^>]*>',
      multiLine: true,
      caseSensitive: false,
    );
    return htmlString.replaceAll(exp, '').trim();
  }

  Widget _buildFormsCard(AssignedFormModel form) {
    return _buildInfoCard(
      title: form.formTitle,
      icon: Icons.person_search_outlined,
      description: Bidi.stripHtmlIfNeeded(form.formDesc),
      buttonText: form.btnText,
      formAccountNo: form.formAccountno,
      form: form,
      onTap: _navigateToForm(form),
    );
  }

  dynamic _navigateToForm(AssignedFormModel form) {
    if (form.allowMultiple == 0 && form.isFilled == 'Yes') {
      return null;
    } else {
      if (form.formAccountno != '' &&
          form.formLink != '' &&
          form.linkForm == 0) {
        return () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FormMainScreen(
                    formAccountNo: form.formAccountno,
                    formToken: form.formLink,
                    isFrom: 'dashboard',
                    refreshForms: null,
                  ),
            ),
          );
        };
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: onPressed != null ? Colors.transparent : Colors.grey.shade300,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            // Icon(icon, size: 16, color: AppColors.primaryColor),
            // const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: onPressed != null ? Colors.black : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String description,
    required String buttonText,
    required VoidCallback? onTap,
    required String formAccountNo,
    required AssignedFormModel form,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        // width: double.infinity,
        // height: MediaQuery.of(context).size.height * 0.2,
        child: Card(
          elevation: 0,
          color: AppColors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          children: [
                            TextSpan(text: description),

                            // TextSpan(
                            //   text: '  More',
                            //   style: TextStyle(
                            //     color: AppColors.primaryColor,
                            //     fontWeight: FontWeight.normal,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(
                      icon: Icons.visibility,
                      label: 'Submissions',
                      color: AppColors.agreementCardViewBtnColor,
                      onPressed: _handleSubmissionsNavigation(
                        formAccountNo,
                        title,
                        form,
                        context,
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                          ),
                          child: Text(
                            buttonText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

dynamic _handleSubmissionsNavigation(
  String formAccountNo,
  String formTitle,
  AssignedFormModel form,
  BuildContext context,
) {
  if (form.allowMultiple == 1 && form.isFilled == 'NO') {
    return null;
  } else {
    if (formAccountNo != '' && formTitle != '') {
      return () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => FormSubmissionsScreen(
                  formAccountNo: formAccountNo,
                  formTitle: formTitle,
                ),
          ),
        );
      };
    }
  }
}

class StatItem {
  final String label;
  final String value;

  StatItem(this.label, this.value);
}

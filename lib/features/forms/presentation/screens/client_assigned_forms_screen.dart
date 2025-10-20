import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/features/dashboard/domain/models/dashboard_data_model.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import 'package:voicealerts_obs/features/forms/presentation/bloc/forms_bloc.dart';
import 'package:voicealerts_obs/features/forms/presentation/screens/form_main_screen.dart';
import 'package:voicealerts_obs/features/forms/presentation/screens/form_submissions_screen.dart';

class ClientAssignedFormsScreen extends StatefulWidget {
  final String? title;
  final String isFrom;
  const ClientAssignedFormsScreen({
    super.key,
    required this.title,
    required this.isFrom,
  });

  @override
  State<ClientAssignedFormsScreen> createState() =>
      _ClientAssignedFormsScreenState();
}

class _ClientAssignedFormsScreenState extends State<ClientAssignedFormsScreen> {
  List<AssignedFormModel> _clientAssignedForms = [];
  @override
  void initState() {
    super.initState();
    context.read<FormsBloc>().add(LoadClientAssignedForms());
  }

  void _refreshForms() {
    context.read<FormsBloc>().add(LoadClientAssignedForms());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.title != null ? AppBar(title: Text(widget.title!)) : null,
      body: BlocConsumer<FormsBloc, FormsState>(
        listener: (context, state) {
          if (state is ClientAssignedFormsError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              CustomErrorDialog.show(
                context: context,
                onRetry: () {
                  // Your retry logic here
                  Navigator.pop(context);
                  _refreshForms();
                },
              );
            });
          }
        },
        builder: (context, state) {
          if (state is ClientAssignedFormsLoading) {
            return const DashboardShimmer();
          }
          if (state is ClientAssignedFormsLoaded) {
            _clientAssignedForms = state.clientAssignedForms;
            return _buildAssignedFormsList(_clientAssignedForms);
          }
          if (state is ClientAssignedFormsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Something went wrong Please try again',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (_clientAssignedForms.isEmpty) {
            return const SizedBox();
          } else {
            return _buildAssignedFormsList(_clientAssignedForms);
          }
        },
      ),
    );
  }

  _buildAssignedFormsList(List<AssignedFormModel> assignedForms) {
    return ListView.builder(
      shrinkWrap: true,
      // physics: NeverScrollableScrollPhysics(),
      itemCount: assignedForms.length,
      itemBuilder: (context, index) {
        final form = assignedForms[index];
        return _buildKycOnboardingCard(form);
      },
    );
  }

  Widget _buildKycOnboardingCard(AssignedFormModel form) {
    return _buildInfoCard(
      title: form.formTitle,
      icon: Icons.person_search_outlined,
      description: Bidi.stripHtmlIfNeeded(form.formDesc),
      buttonText: form.btnText,
      onTap: _navigateToForm(form),
      onSubmissionsPressed: _handleSubmissionsNavigation(
        form.formAccountno,
        form.formTitle,
        form,
        context,
      ),
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
                    isFrom: widget.isFrom,
                    refreshForms: _refreshForms,
                  ),
            ),
          );
        };
      }
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

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String description,
    required String buttonText,
    required VoidCallback? onTap,
    required VoidCallback? onSubmissionsPressed,
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
                    const SizedBox(width: 30),
                    _buildActionButton(
                      icon: Icons.visibility,
                      label: 'Submissions',
                      color: AppColors.agreementCardViewBtnColor,
                      onPressed: onSubmissionsPressed,
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

  Widget retryButton({required VoidCallback onPressed, required String text}) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }
}

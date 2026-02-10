import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/rfq/data/repositories/rfq_repository_impl.dart';
import 'package:voicealerts_obs/features/rfq/data/services/rfq_service.dart';
import 'package:voicealerts_obs/features/rfq/presentation/bloc/rfq_bloc.dart';
import 'package:voicealerts_obs/features/rfq/presentation/widgets/rfq_stepper_form.dart';

/// RFQ Form Screen - Main screen for displaying the RFQ dynamic form
class RfqFormScreen extends StatelessWidget {
  final VoidCallback? onNavigateBack;
  final String? rfqAccountNo; // Optional: for edit mode

  const RfqFormScreen({super.key, this.onNavigateBack, this.rfqAccountNo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = RfqBloc(
          rfqRepository: RfqRepositoryImpl(rfqService: RfqService()),
        );
        // Load form data based on mode
        if (rfqAccountNo != null && rfqAccountNo!.isNotEmpty) {
          bloc.add(LoadRfqFormDataForEdit(rfqAccountNo!));
        } else {
          bloc.add(const LoadRfqFormData());
        }
        return bloc;
      },
      child: _RfqFormScreenContent(onNavigateBack: onNavigateBack),
    );
  }
}

class _RfqFormScreenContent extends StatelessWidget {
  final VoidCallback? onNavigateBack;

  const _RfqFormScreenContent({this.onNavigateBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Platform.isIOS
                ? Icons.arrow_back_ios_new_rounded
                : Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () {
            if (onNavigateBack != null) {
              onNavigateBack!();
            } else {
              context.pop();
            }
          },
        ),
        title: BlocBuilder<RfqBloc, RfqState>(
          builder: (context, state) {
            final title =
                state.formDefinition?.settings?.title ??
                'Request for Quotation';
            return Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          // Progress indicator
          BlocBuilder<RfqBloc, RfqState>(
            builder: (context, state) {
              if (state.formDefinition == null) return const SizedBox();

              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.currentStep + 1}/${state.totalSteps}',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<RfqBloc, RfqState>(
          builder: (context, state) {
            // Show header description on first step
            if (state.status == RfqFormStatus.loaded &&
                state.isFirstStep &&
                state.formDefinition?.settings != null) {
              return Column(
                children: [
                  // RFQ Header with description
                  _RfqHeader(settings: state.formDefinition!.settings!),

                  // Divider
                  Divider(height: 1, color: Colors.grey.shade200),

                  // Form content
                  Expanded(
                    child: RfqStepperForm(onSubmitSuccess: onNavigateBack),
                  ),
                ],
              );
            }

            return RfqStepperForm(onSubmitSuccess: onNavigateBack);
          },
        ),
      ),
    );
  }
}

/// RFQ Header widget showing the title and description
class _RfqHeader extends StatelessWidget {
  final dynamic settings;

  const _RfqHeader({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.heading != null && settings.heading.isNotEmpty)
            Text(
              settings.heading,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          if (settings.shortDesc != null && settings.shortDesc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              settings.shortDesc,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Standalone RFQ Form Widget that can be embedded in other screens
class RfqFormWidget extends StatelessWidget {
  final VoidCallback? onSubmitSuccess;

  const RfqFormWidget({super.key, this.onSubmitSuccess});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => RfqBloc(
            rfqRepository: RfqRepositoryImpl(rfqService: RfqService()),
          )..add(const LoadRfqFormData()),
      child: RfqStepperForm(onSubmitSuccess: onSubmitSuccess),
    );
  }
}

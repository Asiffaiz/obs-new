import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import 'package:voicealerts_obs/features/forms/presentation/bloc/forms_bloc.dart';
import 'package:voicealerts_obs/features/forms/presentation/widgets/form_screen.dart';

class FormMainScreen extends StatefulWidget {
  final String formAccountNo;
  final String formToken;
  final String isFrom;
  final void Function()? refreshForms;
  final void Function()? refreshStepper;
  const FormMainScreen({
    super.key,
    required this.formAccountNo,
    required this.formToken,
    required this.isFrom,
    this.refreshForms,
    this.refreshStepper,
  });

  @override
  State<FormMainScreen> createState() => _FormMainScreenState();
}

class _FormMainScreenState extends State<FormMainScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FormsBloc>().add(
      LoadFormsData(
        formAccountNo: widget.formAccountNo,
        formToken: widget.formToken,
      ),
    );
  }

  void handleScreenNavigation() {
    if (widget.isFrom == 'dashboard') {
      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      });
    } else if (widget.isFrom == 'dashboard_forms' &&
        widget.refreshForms != null) {
      Navigator.pop(context);
      widget.refreshForms!();
    } else if (widget.isFrom == 'side_menu_forms' &&
        widget.refreshForms != null) {
      Navigator.pop(context);
      widget.refreshForms!();
    } else if (widget.isFrom == 'onboarding' && widget.refreshStepper != null) {
      Navigator.pop(context);
      widget.refreshStepper!();
    } else if (widget.isFrom == 'product_service') {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocConsumer<FormsBloc, FormsState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is FormsLoading) {
            return SafeArea(child: DashboardShimmer());
          } else if (state is FormsLoaded) {
            return DynamicFormScreen(
              formTitle: state.formsData[0]['form_title'],
              apiJson: state.formsData[0],
              formAccountNo: widget.formAccountNo,
              formToken: widget.formToken,
              handleScreenNavigation: handleScreenNavigation,
            );
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: retryButton(
                  onPressed: () {
                    context.read<FormsBloc>().add(
                      LoadFormsData(
                        formAccountNo: widget.formAccountNo,
                        formToken: widget.formToken,
                      ),
                    );
                  },
                  text: 'Retry',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final state = context.watch<FormsBloc>().state;
    if (state is FormsLoaded) {
      return AppBar(title: Text(state.formsData[0]['form_title']));
    }
    return AppBar();
  }

  Widget retryButton({required VoidCallback onPressed, required String text}) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }
}

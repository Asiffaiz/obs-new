import 'package:flutter/material.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';

enum StepStatus {
  completed,
  current,
  pending,
}

class StepperItem {
  final String title;
  final StepStatus status;
  final String? subtitle;
  
  const StepperItem({
    required this.title,
    required this.status,
    this.subtitle,
  });
}

class OnboardingStepper extends StatelessWidget {
  final List<StepperItem> steps;
  final int currentStep;
  final Function(int) onStepTapped;
  final bool isVertical;

  const OnboardingStepper({
    Key? key,
    required this.steps,
    required this.currentStep,
    required this.onStepTapped,
    this.isVertical = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isVertical 
        ? _buildVerticalStepper() 
        : _buildHorizontalStepper();
  }

  Widget _buildHorizontalStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          
          return Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              // If even index, show step circle
              if (index % 2 == 0) {
                final stepIndex = index ~/ 2;
                return Expanded(
                  child: _buildStepItem(stepIndex, isCompact: isCompact),
                );
              } else {
                // If odd index, show connector line
                return Expanded(
                  child: _buildConnector(index ~/ 2),
                );
              }
            }),
          );
        },
      ),
    );
  }

  Widget _buildVerticalStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length * 2 - 1, (index) {
          // If even index, show step circle
          if (index % 2 == 0) {
            final stepIndex = index ~/ 2;
            return _buildStepItemVertical(stepIndex);
          } else {
            // If odd index, show connector line
            return _buildConnectorVertical(index ~/ 2);
          }
        }),
      ),
    );
  }

  Widget _buildStepItem(int index, {bool isCompact = false}) {
    final step = steps[index];
    final isCompleted = step.status == StepStatus.completed;
    final isCurrent = step.status == StepStatus.current;

    return GestureDetector(
      onTap: () => onStepTapped(index),
      child: Column(
        children: [
          Container(
            width: isCompact ? 40 : 48,
            height: isCompact ? 40 : 48,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? Colors.green 
                  : isCurrent 
                      ? Colors.blue 
                      : Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted 
                    ? Colors.green 
                    : isCurrent 
                        ? Colors.blue 
                        : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white)
                  : Icon(
                      Icons.circle,
                      size: 16,
                      color: isCurrent ? Colors.white : Colors.grey.shade400,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.title,
            style: TextStyle(
              color: isCurrent ? Colors.black : Colors.grey.shade600,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              fontSize: isCompact ? 12 : 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (step.subtitle != null && step.subtitle!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Colors.green.shade50 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                step.subtitle!,
                style: TextStyle(
                  fontSize: isCompact ? 10 : 12,
                  color: isCompleted ? Colors.green : Colors.grey.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepItemVertical(int index) {
    final step = steps[index];
    final isCompleted = step.status == StepStatus.completed;
    final isCurrent = step.status == StepStatus.current;

    return GestureDetector(
      onTap: () => onStepTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Colors.green 
                    : isCurrent 
                        ? Colors.blue 
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted 
                      ? Colors.green 
                      : isCurrent 
                          ? Colors.blue 
                          : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Icon(
                        Icons.circle,
                        size: 12,
                        color: isCurrent ? Colors.white : Colors.grey.shade400,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: isCurrent ? Colors.black : Colors.grey.shade600,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  if (step.subtitle != null && step.subtitle!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? Colors.green.shade50 
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        step.subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted ? Colors.green : Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector(int beforeIndex) {
    final beforeStep = steps[beforeIndex];
    final afterStep = steps[beforeIndex + 1];
    
    final isBeforeCompleted = beforeStep.status == StepStatus.completed;
    final isAfterCompleted = afterStep.status == StepStatus.completed;
    final isAfterCurrent = afterStep.status == StepStatus.current;
    
    Color connectorColor;
    if (isBeforeCompleted && isAfterCompleted) {
      connectorColor = Colors.green;
    } else if (isBeforeCompleted && isAfterCurrent) {
      connectorColor = Colors.blue;
    } else {
      connectorColor = Colors.grey.shade300;
    }
    
    return Container(
      height: 2,
      color: connectorColor,
    );
  }

  Widget _buildConnectorVertical(int beforeIndex) {
    final beforeStep = steps[beforeIndex];
    final afterStep = steps[beforeIndex + 1];
    
    final isBeforeCompleted = beforeStep.status == StepStatus.completed;
    final isAfterCompleted = afterStep.status == StepStatus.completed;
    final isAfterCurrent = afterStep.status == StepStatus.current;
    
    Color connectorColor;
    if (isBeforeCompleted && isAfterCompleted) {
      connectorColor = Colors.green;
    } else if (isBeforeCompleted && isAfterCurrent) {
      connectorColor = Colors.blue;
    } else {
      connectorColor = Colors.grey.shade300;
    }
    
    return Container(
      margin: const EdgeInsets.only(left: 16),
      width: 2,
      height: 24,
      color: connectorColor,
    );
  }
}

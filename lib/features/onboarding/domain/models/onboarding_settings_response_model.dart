class OnboardingSettingsResponseModel {
  final Map<String, dynamic> steps;
  final int totalSteps;
  final int progress;

  const OnboardingSettingsResponseModel({
    required this.steps,
    required this.totalSteps,
    required this.progress,
  });

  factory OnboardingSettingsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final stepsData = data['steps'] as Map<String, dynamic>? ?? {};
    
    // Transform API response from list to map format
    final List<dynamic> stepsList = stepsData['steps'] as List<dynamic>? ?? [];
    final Map<String, dynamic> stepsMap = {};

    for (var step in stepsList) {
      final stepMap = step as Map<String, dynamic>;
      final title = stepMap['title'] as String? ?? '';
      
      // Skip agreements_details as requested
      final stepConfig = <String, dynamic>{
        'form': stepMap['form'] ?? '',
        'allowSkip': stepMap['allowSkip'] ?? 0,
        'enable': stepMap['isEnabled'] ?? 0, // Map isEnabled to enable
        'isFilled': stepMap['isFilled'] ?? 0,
        'type': stepMap['type'] ?? '',
        'form_token': stepMap['formToken'] ?? '', // Map formToken to form_token
        'isSkipped': stepMap['isSkipped'] ?? 0,
        'allow_multiple': stepMap['allow_multiple'] ?? 0,
        'description': stepMap['form_desc'] ?? '', // Map form_desc to description
        'date': stepMap['date'] ?? '', // Store date if available
        'form_status': stepMap['form_status'] ?? '', // Store form_status if available
        'title': title, // Store title for form data
      };

      stepsMap[title] = stepConfig;
    }

    return OnboardingSettingsResponseModel(
      steps: stepsMap,
      totalSteps: stepsData['total_steps'] as int? ?? stepsList.length,
      progress: stepsData['progress'] as int? ?? 0,
    );
  }
}


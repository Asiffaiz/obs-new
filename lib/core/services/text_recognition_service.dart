import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:voicealerts_obs/core/services/openai_service.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';

class TextRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );
    return recognizedText.text;
  }

  Future<BusinessCard> extractBusinessCardInfo(
    String imagePath, {
    bool useLocalProcessing = false,
  }) async {
    try {
      // Step 1: Extract raw text using Google ML Kit
      final rawText = await extractText(imagePath);

      // Skip OpenAI if offline mode is requested or text is too short or empty
      if (useLocalProcessing || rawText.trim().length < 10) {
        print(
          'Using local processing: useLocalProcessing=$useLocalProcessing, textLength=${rawText.trim().length}',
        );
        return _fallbackExtraction(rawText, imagePath);
      }

      try {
        // Step 2: Use OpenAI to process and structure the extracted text (only in online mode)
        final aiProcessedData = await OpenAIService.processBusinessCardText(
          rawText,
        );

        // Step 3: Map the AI processed data to our BusinessCard model
        return _mapAIDataToBusinessCard(aiProcessedData, imagePath);
      } catch (aiError) {
        // If OpenAI processing fails, fall back to traditional extraction
        print(
          'AI processing failed: $aiError. Falling back to local extraction.',
        );
        return _fallbackExtraction(rawText, imagePath);
      }
    } catch (e) {
      print('Text extraction error: $e');
      throw Exception('Failed to extract business card information: $e');
    }
  }

  BusinessCard _mapAIDataToBusinessCard(
    Map<String, dynamic> aiData,
    String imagePath,
  ) {
    // Map the AI-processed data to our BusinessCard model
    String fullName = '';

    // Handle various name field formats the API might return
    if (aiData.containsKey('name') && aiData['name'] != null) {
      fullName = aiData['name'];
    } else if (aiData.containsKey('first_name') &&
        aiData.containsKey('last_name')) {
      // Some responses might split the name
      final firstName = aiData['first_name'] ?? '';
      final lastName = aiData['last_name'] ?? '';
      fullName = '$firstName $lastName'.trim();
    }

    return BusinessCard(
      name: fullName,
      company: aiData['company'] ?? 'N/A',
      jobTitle: aiData['job_title'] ?? 'N/A',
      phoneNumber: aiData['phone'] ?? 'N/A',
      email: aiData['email'] ?? 'N/A',
      website:
          aiData['website'] != null && aiData['website'].isNotEmpty
              ? aiData['website']
              : null,
      address:
          aiData['address'] != null && aiData['address'].isNotEmpty
              ? aiData['address']
              : null,
      imagePath: imagePath,
    );
  }

  // Fallback method using the original regex-based extraction
  BusinessCard _fallbackExtraction(String text, String imagePath) {
    // Combine multiple spaces and line breaks to ensure consistent parsing
    final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ');
    final lines = text.split('\n');

    // Extract information using regular expressions and heuristics
    String name = '';
    String company = '';
    String jobTitle = '';
    String phoneNumber = '';
    String email = '';
    String website = '';
    String address = '';

    // Enhanced regular expressions for better extraction
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
      caseSensitive: false,
    );

    // More comprehensive phone regex to catch various formats
    final phoneRegex = RegExp(
      r'\b(?:(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}|\d{10}|\d{3}[-.\s]?\d{3}[-.\s]?\d{4}|\(\d{3}\)\s*\d{3}[-.\s]?\d{4}|\d{3}\.\d{3}\.\d{4})\b',
    );

    // Improved website regex to catch more variations
    final websiteRegex = RegExp(
      r'\b(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9][a-zA-Z0-9-]*\.[a-zA-Z]{2,}(?:\.[a-zA-Z]{2,})?(?:\/[a-zA-Z0-9_-]*)*\b',
      caseSensitive: false,
    );

    // Search in both the raw text and line by line for structured data
    // First try to find matches in the entire normalized text
    final allEmailMatches = emailRegex.allMatches(normalizedText);
    if (allEmailMatches.isNotEmpty) {
      email = allEmailMatches.first.group(0) ?? '';
    }

    final allPhoneMatches = phoneRegex.allMatches(normalizedText);
    if (allPhoneMatches.isNotEmpty) {
      phoneNumber = allPhoneMatches.first.group(0) ?? '';
    }

    final allWebsiteMatches = websiteRegex.allMatches(normalizedText);
    if (allWebsiteMatches.isNotEmpty) {
      website = allWebsiteMatches.first.group(0) ?? '';
    }

    // If we still don't have all the data, try line by line
    if (email.isEmpty || phoneNumber.isEmpty || website.isEmpty) {
      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        // Skip if we already found this info
        if (email.isEmpty) {
          final emailMatches = emailRegex.allMatches(line);
          if (emailMatches.isNotEmpty) {
            email = emailMatches.first.group(0) ?? '';
          }
        }

        if (phoneNumber.isEmpty) {
          final phoneMatches = phoneRegex.allMatches(line);
          if (phoneMatches.isNotEmpty) {
            phoneNumber = phoneMatches.first.group(0) ?? '';
          }
        }

        if (website.isEmpty) {
          final websiteMatches = websiteRegex.allMatches(line);
          if (websiteMatches.isNotEmpty) {
            website = websiteMatches.first.group(0) ?? '';
          }
          // Additional website heuristics
          else if (line.toLowerCase().contains('www.') ||
              (line.toLowerCase().contains('.com') && !line.contains('@')) ||
              line.toLowerCase().contains('.org') ||
              line.toLowerCase().contains('.net')) {
            website = line.trim();
          }
        }
      }
    }

    // Try to look for common email patterns that might have been missed
    if (email.isEmpty) {
      for (String line in lines) {
        if (line.contains('@')) {
          // More permissive pattern to extract emails with any TLD
          final relaxedEmailMatch = RegExp(
            r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
          ).firstMatch(line);
          if (relaxedEmailMatch != null) {
            email = relaxedEmailMatch.group(0) ?? '';
            break;
          }
        }
      }
    }

    // Second pass: Assign name and other information based on position and content
    bool nameAssigned = false;
    bool jobTitleAssigned = false;
    bool companyAssigned = false;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Skip lines that were already identified as structured data
      if ((email.isNotEmpty && line.contains(email)) ||
          (phoneNumber.isNotEmpty && line.contains(phoneNumber)) ||
          (website.isNotEmpty &&
              line.toLowerCase().contains(website.toLowerCase()))) {
        continue;
      }

      // Name is typically one of the first lines and shorter than address
      if (!nameAssigned && line.split(' ').length <= 4) {
        name = line;
        nameAssigned = true;
        continue;
      }

      // Job title often follows the name
      if (nameAssigned && !jobTitleAssigned) {
        jobTitle = line;
        jobTitleAssigned = true;
        continue;
      }

      // Company typically follows job title
      if (jobTitleAssigned && !companyAssigned) {
        company = line;
        companyAssigned = true;
        continue;
      }

      // Remaining lines might be address
      if (companyAssigned) {
        if (address.isEmpty) {
          address = line;
        } else {
          address += ', $line';
        }
      }
    }

    // If we failed to identify core information, make sure we at least have something
    if (name.isEmpty && lines.isNotEmpty) {
      name = lines[0];
    }

    // Look for missing phone number with more relaxed pattern
    if (phoneNumber.isEmpty) {
      // Look for any sequence of 10 digits
      final digitOnlyRegex = RegExp(r'\b\d{10}\b');
      final digitMatches = digitOnlyRegex.allMatches(normalizedText);
      if (digitMatches.isNotEmpty) {
        phoneNumber = digitMatches.first.group(0) ?? '';
        // Format as XXX-XXX-XXXX
        if (phoneNumber.length == 10) {
          phoneNumber =
              '${phoneNumber.substring(0, 3)}-${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}';
        }
      }
    }

    // Handle fallbacks for required fields
    phoneNumber = phoneNumber.isEmpty ? 'N/A' : phoneNumber;
    email = email.isEmpty ? 'N/A' : email;
    company = company.isEmpty ? 'N/A' : company;
    jobTitle = jobTitle.isEmpty ? 'N/A' : jobTitle;

    // Create and return the business card model
    return BusinessCard(
      name: name,
      company: company,
      jobTitle: jobTitle,
      phoneNumber: phoneNumber,
      email: email,
      website: website.isEmpty ? null : website,
      address: address.isEmpty ? null : address,
      imagePath: imagePath,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // API Key should be stored securely, preferably in environment variables
  // For production, use secure storage or server-side proxy
  static String _apiKey = ''; // Empty by default
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';

  // Set the API key - call this during app initialization
  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Process extracted business card text using OpenAI to get structured data
  static Future<Map<String, dynamic>> processBusinessCardText(
    String extractedText,
  ) async {
    if (_apiKey.isEmpty) {
      print('OpenAI API key not set');
      throw Exception('OpenAI API key not configured');
    }

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      // Sanitize the text to remove any problematic characters
      final sanitizedText =
          extractedText
              .replaceAll(
                RegExp(r'[^\x20-\x7E\n]'),
                '',
              ) // Keep only ASCII printable chars
              .trim();

      final Map<String, dynamic> body = {
        'model': 'gpt-4o', // You can use gpt-4 for better results if available
        'messages': [
          {
            'role': 'system',
            'content': '''
            You are a business card data extractor. Extract structured information from 
            OCR text of business cards. Parse the given text and extract the following fields:
            - name (full name)
            - job_title
            - company
            - email
            - phone
            - website
            - address

            Return the data in a JSON format with these fields. If a field is not found, 
            leave it as empty string. Try to clean and format data when possible.
            ''',
          },
          {
            'role': 'user',
            'content':
                'Extract structured data from this business card OCR text: $sanitizedText',
          },
        ],
        'temperature': 0.3, // Lower temperature for more deterministic results
        'response_format': {'type': 'json_object'}, // Ensure JSON response
      };

      print(
        'Sending text to OpenAI: ${sanitizedText.substring(0, sanitizedText.length > 50 ? 50 : sanitizedText.length)}...',
      );

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: headers,
        body: jsonEncode(body),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final String contentString =
            jsonResponse['choices'][0]['message']['content'];

        // Parse the JSON string from the content
        try {
          final Map<String, dynamic> parsedData = jsonDecode(contentString);
          print('Successfully parsed OpenAI response');
          return parsedData;
        } catch (jsonError) {
          print('Failed to parse JSON from OpenAI response: $jsonError');
          print('Raw response: $contentString');
          throw Exception('Invalid JSON response from OpenAI');
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Failed to process business card data: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Exception in OpenAI processing: $e');
      throw Exception('Error processing business card: $e');
    }
  }

  /// Split a full name into first and last name
  static Map<String, String> splitName(String fullName) {
    if (fullName.isEmpty) return {'first': '', 'last': ''};

    final nameParts = fullName.trim().split(' ');
    if (nameParts.length == 1) {
      return {'first': nameParts[0], 'last': ''};
    } else {
      final firstName = nameParts[0];
      final lastName = nameParts.sublist(1).join(' ');
      return {'first': firstName, 'last': lastName};
    }
  }
}

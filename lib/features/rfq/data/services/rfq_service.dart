import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_product_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_submission_model.dart';

/// Service for RFQ API calls
/// Currently uses mock data, replace with actual API calls when ready
class RfqService {
  /// Get RFQ submissions list
  Future<List<RfqSubmission>> getRfqSubmissions() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock submissions data - replace with actual API call
    return _getMockSubmissions();
  }

  /// Get RFQ form data from API
  Future<RfqFormDefinition> getRfqFormData() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock API response - replace with actual API call
    final mockResponse = _getMockRfqData();
    return RfqFormDefinition.fromApiResponse(mockResponse);
  }

  /// Get available products/services for RFQ
  Future<List<RfqProduct>> getRfqProducts() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Get products from mock data
    final mockResponse = _getMockRfqData();
    final servicesList = mockResponse['servicesListing'] as List? ?? [];
    
    return servicesList
        .map((service) => RfqProduct.fromJson(service as Map<String, dynamic>))
        .toList();
  }

  /// Submit RFQ form
  Future<bool> submitRfqForm({
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Implement actual API call
    // final response = await _apiClient.post('/rfq/submit', body: {
    //   'answers': answers,
    //   'currentStep': currentStep,
    //   'totalSteps': totalSteps,
    // });

    return true;
  }

  /// Save RFQ form as draft
  Future<bool> saveRfqFormAsDraft({
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Implement actual API call
    return true;
  }

  /// Mock RFQ data based on provided JSON
  Map<String, dynamic> _getMockRfqData() {
    return {
      "status": 200,
      "message": "success",
      "note": "success",
      "rfqQuestionsListing": [
        {
          "id": 52,
          "question_title": "What is your business",
          "question_type": "textfield",
          "dateAdded": "2025-10-15T18:21:53.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 238238
        },
        {
          "id": 49,
          "question_title": "Upload Image",
          "question_type": "fileinput",
          "dateAdded": "2025-02-15T00:13:39.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 470470
        },
        {
          "id": 48,
          "question_title": "Upload Document",
          "question_type": "fileinput",
          "dateAdded": "2025-02-15T00:13:12.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 572572
        },
        {
          "id": 46,
          "question_title": "Testing label Field",
          "question_type": "label",
          "dateAdded": "2025-02-14T21:19:09.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 209209
        },
        {
          "id": 31,
          "question_title": "How many Human Resources do you need?",
          "question_type": "dropdown",
          "dateAdded": "2024-04-12T16:58:13.000Z",
          "question_options": [
            {"id": 174, "question_id": 31, "question_options": "1-10"},
            {"id": 175, "question_id": 31, "question_options": "11-20"},
            {"id": 176, "question_id": 31, "question_options": "21-40"}
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 522522
        },
        {
          "id": 53,
          "question_title": "What is your location",
          "question_type": "textfield",
          "dateAdded": "2025-10-15T18:22:26.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 238238
        },
        {
          "id": 51,
          "question_title": "Testing Labels 1234",
          "question_type": "label",
          "dateAdded": "2025-03-19T16:53:48.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 522522
        },
        {
          "id": 54,
          "question_title": "What Services you needed",
          "question_type": "checkbox",
          "dateAdded": "2025-10-15T18:23:35.000Z",
          "question_options": [
            {"id": 177, "question_id": 54, "question_options": "White Lable"},
            {
              "id": 178,
              "question_id": 54,
              "question_options": "White lable + Support services"
            },
            {
              "id": 179,
              "question_id": 54,
              "question_options": "White Lable + Installation Serivces"
            }
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 238238
        },
        {
          "id": 45,
          "question_title": "Upload Help Document",
          "question_type": "fileinput",
          "dateAdded": "2025-02-14T21:18:24.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 209209
        },
        {
          "id": 15,
          "question_title":
              "Tell us about your Idea or Business? (High Level Concept)",
          "question_type": "textarea",
          "dateAdded": "2023-12-21T22:20:55.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 209209
        },
        {
          "id": 16,
          "question_title": "What is the outcome that you are trying to achieve?",
          "question_type": "checkbox",
          "dateAdded": "2023-12-21T22:21:19.000Z",
          "question_options": [
            {
              "id": 132,
              "question_id": 16,
              "question_options":
                  "RTLS (Real Time Location Services) Software to track Assets and or Humans."
            },
            {
              "id": 133,
              "question_id": 16,
              "question_options":
                  "WMS (Warehouse Management Systems) to track inventory."
            },
            {
              "id": 134,
              "question_id": 16,
              "question_options":
                  "SDK (Software Development Kit) for mobile applications to provide wayfinding or indoor navigation."
            },
            {
              "id": 135,
              "question_id": 16,
              "question_options":
                  "RFID (Radio Frequency ID) Tags. Hardware only to augment my current solutions."
            }
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 209209
        },
        {
          "id": 17,
          "question_title":
              "What are the key business objectives or challenges that you want to solve?",
          "question_type": "textarea",
          "dateAdded": "2023-12-21T22:22:12.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 209209
        },
        {
          "id": 18,
          "question_title":
              "What are your preferred methods of communication with us?",
          "question_type": "checkbox",
          "dateAdded": "2023-12-21T22:24:11.000Z",
          "question_options": [
            {"id": 136, "question_id": 18, "question_options": "Phone "},
            {"id": 137, "question_id": 18, "question_options": "Email "},
            {
              "id": 138,
              "question_id": 18,
              "question_options":
                  "Third party messaging application like Whatsapp, Skype, Slack, Google Chat etc."
            }
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 209209
        },
        {
          "id": 19,
          "question_title":
              "What is your preferred method of payment for your clients?",
          "question_type": "radio",
          "dateAdded": "2023-12-22T21:50:13.000Z",
          "question_options": [
            {"id": 91, "question_id": 19, "question_options": "Bank Transfer"},
            {"id": 92, "question_id": 19, "question_options": "Wire Transfer"},
            {"id": 93, "question_id": 19, "question_options": "Credit Card"}
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 572572
        },
        {
          "id": 20,
          "question_title":
              "What are your primary billing terms for your clients?",
          "question_type": "dropdown",
          "dateAdded": "2023-12-22T21:51:10.000Z",
          "question_options": [
            {"id": 60, "question_id": 20, "question_options": "Cash"},
            {"id": 61, "question_id": 20, "question_options": "30 Days/ Monthly"},
            {"id": 62, "question_id": 20, "question_options": "One Time/ Project"},
            {"id": 63, "question_id": 20, "question_options": "Prepaid Only"}
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 572572
        },
        {
          "id": 21,
          "question_title":
              "Does this Request for Quotation logic make sense for your clients?",
          "question_type": "dropdown",
          "dateAdded": "2024-01-02T18:02:36.000Z",
          "question_options": [
            {"id": 64, "question_id": 21, "question_options": "Yes"},
            {"id": 65, "question_id": 21, "question_options": "No"},
            {"id": 66, "question_id": 21, "question_options": "Not Sure"}
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 572572
        },
        {
          "id": 22,
          "question_title":
              "If Other: Please tell us what Access Point Model or Device Name is in use?",
          "question_type": "textfield",
          "dateAdded": "2024-02-06T21:20:13.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 572572
        },
        {
          "id": 23,
          "question_title":
              "What are your current Network Access Points (Installed)?",
          "question_type": "dropdown",
          "dateAdded": "2024-02-20T16:45:26.000Z",
          "question_options": [
            {"id": 79, "question_id": 23, "question_options": "None"},
            {"id": 80, "question_id": 23, "question_options": "Cisco"},
            {"id": 81, "question_id": 23, "question_options": "Aruba Networks"},
            {"id": 82, "question_id": 23, "question_options": "Other"},
            {"id": 83, "question_id": 23, "question_options": "Noccella"}
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 572572
        },
        {
          "id": 26,
          "question_title":
              "How satisfied are you with the clarity and completeness of the RFQ document?",
          "question_type": "textfield",
          "dateAdded": "2024-03-15T18:30:39.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 470470
        },
        {
          "id": 27,
          "question_title":
              "Did the RFQ process effectively address your organization's requirements and objectives?",
          "question_type": "textfield",
          "dateAdded": "2024-03-15T18:31:03.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 470470
        },
        {
          "id": 32,
          "question_title": "Testing RFQ",
          "question_type": "dropdown",
          "dateAdded": "2024-08-08T12:10:38.000Z",
          "question_options": [
            {"id": 97, "question_id": 32, "question_options": "test01"},
            {"id": 98, "question_id": 32, "question_options": "test02"},
            {"id": 99, "question_id": 32, "question_options": "test03"}
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 470470
        },
        {
          "id": 38,
          "question_title": "What is the covered area? (Area in sqm)",
          "question_type": "dropdown",
          "dateAdded": "2025-02-06T19:32:45.000Z",
          "question_options": [
            {"id": 166, "question_id": 38, "question_options": "500 sqm"},
            {"id": 167, "question_id": 38, "question_options": "1000 sqm"},
            {"id": 168, "question_id": 38, "question_options": "1500 sqm"}
          ],
          "domain_name": "",
          "isMandatory": 1,
          "group_id": 733733
        },
        {
          "id": 39,
          "question_title": "Number of Assets need to be tracked?",
          "question_type": "radio",
          "dateAdded": "2025-02-06T19:39:22.000Z",
          "question_options": [
            {"id": 151, "question_id": 39, "question_options": "less than 50"},
            {"id": 152, "question_id": 39, "question_options": "Less than 150"},
            {"id": 153, "question_id": 39, "question_options": "Less than 500"},
            {"id": 154, "question_id": 39, "question_options": "More than 500"}
          ],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 733733
        },
        {
          "id": 40,
          "question_title": "What is the Type Of Asset?",
          "question_type": "radio",
          "dateAdded": "2025-02-06T19:45:00.000Z",
          "question_options": [
            {"id": 155, "question_id": 40, "question_options": "Human"},
            {"id": 156, "question_id": 40, "question_options": "Not Human"}
          ],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 733733
        },
        {
          "id": 41,
          "question_title": "What kind of Technology required?",
          "question_type": "checkbox",
          "dateAdded": "2025-02-06T19:46:28.000Z",
          "question_options": [
            {"id": 157, "question_id": 41, "question_options": "BLE-Navigation"},
            {"id": 158, "question_id": 41, "question_options": "AoA-QPE"},
            {"id": 159, "question_id": 41, "question_options": "BLE-MN"},
            {"id": 160, "question_id": 41, "question_options": "UWB-NPE"}
          ],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 733733
        },
        {
          "id": 42,
          "question_title": "How you need to deploy the desired technology?",
          "question_type": "checkbox",
          "dateAdded": "2025-02-06T19:47:54.000Z",
          "question_options": [
            {"id": 171, "question_id": 42, "question_options": "Cloud"},
            {"id": 172, "question_id": 42, "question_options": "On-Premise"},
            {"id": 173, "question_id": 42, "question_options": "mail"}
          ],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 733733
        },
        {
          "id": 43,
          "question_title": "What kind of Solution Required?",
          "question_type": "dropdown",
          "dateAdded": "2025-02-06T19:50:46.000Z",
          "question_options": [
            {
              "id": 163,
              "question_id": 43,
              "question_options": "Onboardsoft Partner"
            },
            {"id": 164, "question_id": 43, "question_options": "White Lable"}
          ],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 733733
        },
        {
          "id": 44,
          "question_title":
              "How you can contact for Query? Please reply on jshahid@tcpaas.com",
          "question_type": "textfield",
          "dateAdded": "2025-02-06T19:52:15.000Z",
          "question_options": [],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 733733
        },
        {
          "id": 47,
          "question_title": "Initial Inquiry",
          "question_type": "simple_text",
          "dateAdded": "2025-02-14T21:19:59.000Z",
          "question_options": [
            {
              "id": 170,
              "question_id": 47,
              "question_options":
                  "<p>Initial inquiry will be conducted after the completion of the process1324256</p>"
            }
          ],
          "domain_name": "",
          "isMandatory": 0,
          "group_id": 209209
        }
      ],
      "rfqQuestionGroupsListing": [
        {
          "id": 16,
          "group_title": "Introductory Questions",
          "group_desc":
              "Dive into our 'Introductory Questions' to personalize your experience with tailored insights.",
          "group_id": 209209,
          "group_sequence": 1
        },
        {
          "id": 29,
          "group_title": "Test-Jazzy-RFQ",
          "group_desc": "Testing for RFQ",
          "group_id": 733733,
          "group_sequence": 1
        },
        {
          "id": 30,
          "group_title": "Test 321",
          "group_desc": "Zohair Bhai RFQ",
          "group_id": 238238,
          "group_sequence": 1
        },
        {
          "id": 17,
          "group_title": "Preferences Profile",
          "group_desc": "Explore your preferences in our 'Preferences Profile' section.",
          "group_id": 572572,
          "group_sequence": 2
        },
        {
          "id": 18,
          "group_title": "Feedback & Suggestions",
          "group_desc":
              "Share your thoughts and ideas in our 'Feedback & Suggestions' section.",
          "group_id": 470470,
          "group_sequence": 3
        },
        {
          "id": 26,
          "group_title": "Hiring",
          "group_desc": "Staffing",
          "group_id": 522522,
          "group_sequence": 5
        }
      ],
      "rfq_settings": [
        {
          "id": 1,
          "accountno": "925329925329",
          "email": "info@onboardsoft.com",
          "send_to_agent": "Yes",
          "title": "Request for Quotation",
          "heading": "New RFQ",
          "short_desc":
              "A Request for Quotation (RFQ) is a document or formal process used in business and procurement to solicit price quotes from potential suppliers or vendors."
        }
      ]
    };
  }

  /// Mock submissions data
  List<RfqSubmission> _getMockSubmissions() {
    return [
      RfqSubmission(
        id: 1,
        submissionId: 'RFQ-2025-001',
        status: 'submitted',
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
        title: 'Software License Inquiry',
        totalSteps: 6,
        completedSteps: 6,
      ),
      RfqSubmission(
        id: 2,
        submissionId: 'RFQ-2025-002',
        status: 'draft',
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
        title: 'Channel Partner Portal',
        totalSteps: 6,
        completedSteps: 3,
      ),
      RfqSubmission(
        id: 3,
        submissionId: 'RFQ-2025-003',
        status: 'pending',
        submittedAt: DateTime.now().subtract(const Duration(hours: 12)),
        title: 'Mobile Application Services',
        totalSteps: 6,
        completedSteps: 6,
      ),
      RfqSubmission(
        id: 4,
        submissionId: 'RFQ-2025-004',
        status: 'approved',
        submittedAt: DateTime.now().subtract(const Duration(days: 5)),
        title: 'Asset Tracking System',
        totalSteps: 6,
        completedSteps: 6,
      ),
    ];
  }
}


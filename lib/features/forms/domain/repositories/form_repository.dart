abstract class FormsRepository {
  /// Get all agreements for the current user
  Future<List<dynamic>> getFormsData(String formAccountNo, String formToken);
  Future<List<dynamic>> getClientAssignedForms();
  Future<List<dynamic>> getFormSubmissions(String formAccountNo);
}

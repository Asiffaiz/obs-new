class AppState {
  // private constructor
  AppState._privateConstructor();

  // the single instance
  static final AppState _instance = AppState._privateConstructor();

  // getter to access instance
  static AppState get instance => _instance;

  // your global variable
  bool isShowMandatoryDialog = true;
}

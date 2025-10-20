# Convoso

## Getting Started

### Prerequisites

- Flutter SDK (version ^3.7.2)
- Dart SDK
- Android Studio / Xcode for emulators

### Setup Firebase

1. Create a new Firebase project
2. Add Android and iOS apps to your Firebase project
3. Download the Firebase configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)

### Installation

1. Clone the repository
2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

- `lib/core/`: Core functionality, constants, utilities, and shared widgets
- `lib/features/auth/`: Authentication feature with domain, data, and presentation layers
- `lib/config/`: App configuration, routes, and dependency injection

## Responsive Design

The app is designed to be responsive and works well on both phones and tablets/iPads.

## Dependencies

- State management: `flutter_bloc` and `equatable`
- Authentication: `firebase_auth`, `google_sign_in` and `sign_in_with_apple`
- Routing: `go_router`
- Dependency injection: `get_it`
- Responsive design: `responsive_framework`

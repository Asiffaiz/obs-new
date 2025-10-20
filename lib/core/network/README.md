# API Client Migration Guide

## Overview
This document provides guidance on migrating from feature-specific API clients to the new centralized API client structure.

## New Structure
- `lib/core/network/api_client.dart`: Centralized API client with unified request handling
- `lib/core/network/api_endpoints.dart`: All API endpoints in one place

## Migration Steps

### 1. Update Imports
Replace feature-specific API client imports with the centralized one:

```dart
// Old
import 'api_client.dart';

// New
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
```

### 2. Update API Calls
Replace feature-specific API calls with the centralized client:

```dart
// Old
final response = await _apiClient.checkLogin(email, password);

// New
final response = await _apiClient.post(
  ApiEndpoints.login,
  {'email': email, 'password': password},
);
```

### 3. Update Response Handling
The new ApiResponse has consistent property names:

```dart
// Old
if (response.status == 200) { ... }

// New
if (response.statusCode == 200) { ... }
```

## Benefits
- Single source of truth for API communication
- Consistent error handling
- Easier maintenance when API changes
- Clear separation between network layer and business logic

## Legacy Support
The new ApiResponse class includes backward compatibility:
- `status` getter maps to `statusCode`

## Adding New Endpoints
To add new endpoints, update the `api_endpoints.dart` file:

```dart
// Add new endpoint
static final String newFeatureEndpoint = '$baseUrl/appApis/new_feature';
``` 
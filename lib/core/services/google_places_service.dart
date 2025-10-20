import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/domain/models/address_model.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final String apiKey;

  GooglePlacesService({required this.apiKey});

  Future<List<AddressModel>> getPlacePredictions(String input) async {
    if (input.isEmpty) return [];

    final url =
        '$_baseUrl/autocomplete/json?input=$input&types=address&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;

          return predictions.map((prediction) {
            final placeId = prediction['place_id'] as String;
            final description = prediction['description'] as String;

            // Store place_id in the model
            return AddressModel(
              street: description,
              city: '',
              state: '',
              zipCode: '',
              country: '',
              apartment: '',
              placeId: placeId,
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching place predictions: $e');
      return [];
    }
  }

  Future<AddressModel?> getPlaceDetails(String placeId) async {
    final url = '$_baseUrl/details/json?place_id=$placeId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final addressComponents = result['address_components'] as List;

          String street = '';
          String city = '';
          String state = '';
          String zipCode = '';
          String country = '';

          for (var component in addressComponents) {
            final types = component['types'] as List;
            final longName = component['long_name'] as String;
            final shortName = component['short_name'] as String;

            if (types.contains('street_number')) {
              street = longName;
            } else if (types.contains('route')) {
              street = street.isEmpty ? longName : '$street $longName';
            } else if (types.contains('locality') ||
                types.contains('sublocality')) {
              city = longName;
            } else if (types.contains('administrative_area_level_1')) {
              state = shortName;
            } else if (types.contains('postal_code')) {
              zipCode = longName;
            } else if (types.contains('country')) {
              country = longName;
            }
          }

          return AddressModel(
            street: street.isEmpty ? result['formatted_address'] ?? '' : street,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country,
            apartment: '',
            placeId: placeId,
          );
        }
      }

      return null;
    } catch (e) {
      print('Error fetching place details: $e');
      return null;
    }
  }
}

import 'package:equatable/equatable.dart';

class AddressModel {
  final String street;
  final String apartment;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String? placeId;

  const AddressModel({
    required this.street,
    this.apartment = '',
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.placeId,
  });

  String get fullAddress {
    final apartmentText = apartment.isNotEmpty ? ', $apartment' : '';
    return '$street$apartmentText, $city, $state $zipCode, $country';
  }

  @override
  String toString() => fullAddress;

  // Dummy data for testing
  static List<AddressModel> getDummyAddresses() {
    return [
      const AddressModel(
        street: '123 Main St',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94105',
        country: 'USA',
      ),
      const AddressModel(
        street: '456 Market St',
        apartment: 'Apt 2B',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94103',
        country: 'USA',
      ),
      const AddressModel(
        street: '789 Mission St',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94103',
        country: 'USA',
      ),
      const AddressModel(
        street: '555 Montgomery St',
        apartment: 'Suite 1500',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94111',
        country: 'USA',
      ),
      const AddressModel(
        street: '1 Infinite Loop',
        city: 'Cupertino',
        state: 'CA',
        zipCode: '95014',
        country: 'USA',
      ),
      const AddressModel(
        street: '1600 Amphitheatre Parkway',
        city: 'Mountain View',
        state: 'CA',
        zipCode: '94043',
        country: 'USA',
      ),
      const AddressModel(
        street: '350 5th Ave',
        city: 'New York',
        state: 'NY',
        zipCode: '10118',
        country: 'USA',
      ),
      const AddressModel(
        street: '221B Baker St',
        city: 'London',
        state: 'UK',
        zipCode: 'NW1 6XE',
        country: 'United Kingdom',
      ),
      const AddressModel(
        street: '10 Downing St',
        city: 'London',
        state: 'UK',
        zipCode: 'SW1A 2AA',
        country: 'United Kingdom',
      ),
      const AddressModel(
        street: '1 Chome-1-2 Oshiage',
        apartment: 'Skytree Tower',
        city: 'Sumida City',
        state: 'Tokyo',
        zipCode: '131-0045',
        country: 'Japan',
      ),
    ];
  }
}

// Dummy address list for testing purposes
class DummyAddresses {
  static final List<AddressModel> addresses = [
    const AddressModel(
      street: '123 Main Street',
      city: 'New York',
      state: 'NY',
      zipCode: '10001',
      country: 'United States',
    ),
    const AddressModel(
      street: '456 Park Avenue',
      apartment: 'Apt 202',
      city: 'Los Angeles',
      state: 'CA',
      zipCode: '90001',
      country: 'United States',
    ),
    const AddressModel(
      street: '789 Gulshan e Iqbal',
      city: 'Karachi',
      state: 'Sindh',
      zipCode: '75300',
      country: 'Pakistan',
    ),
    const AddressModel(
      street: '321 Sheikh Zayed Road',
      apartment: 'Tower 5, Floor 15',
      city: 'Dubai',
      state: 'Dubai',
      zipCode: '12345',
      country: 'United Arab Emirates',
    ),
    const AddressModel(
      street: '555 Maple Avenue',
      city: 'Toronto',
      state: 'Ontario',
      zipCode: 'M5V 2A1',
      country: 'Canada',
    ),
  ];
}

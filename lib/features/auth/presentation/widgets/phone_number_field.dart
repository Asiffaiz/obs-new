import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:intl_phone_field/countries.dart';

class PhoneNumberField extends StatefulWidget {
  final Function(String, String) onPhoneNumberChanged;
  final String? Function(String?)? validator;

  const PhoneNumberField({
    super.key,
    required this.onPhoneNumberChanged,
    this.validator,
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  final TextEditingController _controller = TextEditingController();
  String _countryCode = '+1'; // Default country code for USA

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Custom validator wrapper that adapts our validator to the expected type
  String? _phoneValidator(PhoneNumber? phone) {
    if (widget.validator != null && phone != null) {
      return widget.validator!(phone.number);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Filter countries to only include the ones we want
    final supportedCountries =
        countries
            .where(
              (country) => [
                'PK',
                'IN',
                'US',
                'GB',
                'CA',
                'AE',
                'SA',
              ].contains(country.code),
            )
            .toList();

    return IntlPhoneField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      initialCountryCode: 'US',
      // countries: supportedCountries,
      onChanged: (phone) {
        // Pass both country code and phone number to parent
        widget.onPhoneNumberChanged(phone.countryCode, phone.number);
      },
      validator: _phoneValidator,
      dropdownIconPosition: IconPosition.trailing,
      flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),
      showDropdownIcon: true,
      disableLengthCheck: false,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
    );
  }
}

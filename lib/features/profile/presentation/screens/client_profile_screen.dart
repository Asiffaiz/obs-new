import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:voicealerts_obs/core/constants/country_codes.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/form_label.dart';
import 'package:voicealerts_obs/features/auth/domain/models/address_model.dart';
import 'package:voicealerts_obs/features/auth/domain/models/country_model.dart';
import 'package:voicealerts_obs/features/auth/presentation/screens/register_verification_screen.dart';
import 'package:voicealerts_obs/features/auth/presentation/widgets/address_autocomplete.dart';
import 'package:voicealerts_obs/features/auth/presentation/widgets/country_dropdown.dart';
import 'package:voicealerts_obs/features/auth/presentation/widgets/phone_number_field.dart';
import 'package:voicealerts_obs/features/auth/presentation/widgets/scan_with_bussiness_card_signup.dart';
import 'package:voicealerts_obs/features/auth/presentation/widgets/social_auth_buttons_register.dart';
import 'package:voicealerts_obs/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:voicealerts_obs/features/profile/presentation/bloc/profile_event.dart';
import 'package:voicealerts_obs/features/profile/presentation/bloc/profile_state.dart';

import '../../../../config/routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/password_text_field.dart';
import '../../../../core/widgets/responsive_padding.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedCountry;

  String _countryCode = '';
  String _phoneNumber = '';
  //////////
  String initialCountryCode = '+1';
  String initialNumber = '';
  //////////
  bool _isLoading = false;
  AddressModel? _selectedAddress;
  bool _isPoBox = false; // Add this line to track if user is entering a PO Box

  bool _dataConsentChecked = false;
  bool _marketingConsentChecked = false;
  String? _dataConsentError;
  String? _marketingConsentError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handlePhoneNumberChange(String dialCode, String number) {
    _countryCode = dialCode;
    _phoneNumber = number;
  }

  void _handleAddressSelected(AddressModel address) {
    setState(() {
      _selectedAddress = address;
      _addressController.text = address.street;
      _apartmentController.text = address.apartment;
      _cityController.text = address.city;
      _stateController.text = address.state;
      _zipCodeController.text = address.zipCode;

      final countriesList = countries.map((country) => country.name).toList();
      final matchingCountry = countriesList.firstWhere(
        (country) =>
            country == address.country ||
            country.contains(address.country) ||
            address.country.contains(country),
        orElse: () => countries.first.name,
      );
      _selectedCountry = matchingCountry;
    });
  }

  void _handleCountrySelected(String country) {
    setState(() {
      _selectedCountry = country;
    });
  }

  void _signUp() {
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (isFormValid) {
      setState(() {
        _isLoading = true;
      });
      if (_addressController.text.isEmpty) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter an address')),
          );
        });
        return;
      }

      if (_selectedCountry == null) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a country')),
          );
        });
        return;
      }

      // final nameParts = _fullNameController.text.split(' ');
      // final firstName = nameParts.first;
      // final lastName =
      //     nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Prepare registration data for API
      final registrationData = {
        'legal_name':
            _companyNameController.text.isNotEmpty
                ? _companyNameController.text
                : '${_fullNameController.text} Enterprise',
        'company_name':
            _companyNameController.text.isNotEmpty
                ? _companyNameController.text
                : '${_fullNameController.text} Enterprise',
        'email': _emailController.text,
        'password': _passwordController.text,
        'full_name': _fullNameController.text,
        'phone': _phoneNumber.isNotEmpty ? _countryCode + _phoneNumber : '',
        'address': _addressController.text,
        'address2': _apartmentController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zip': _zipCodeController.text,
        'country': _selectedCountry ?? 'United States',
      };

      // Dispatch the registration event
      // print(registrationData);
      context.read<ProfileBloc>().add(UpdateProfile(profile: registrationData));
    }
  }

  @override
  void initState() {
    context.read<ProfileBloc>().add(const LoadProfile());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.loading) {
        } else if (state.status == ProfileStatus.updated) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } else if (state.status == ProfileStatus.error) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Something went wrong try again!')),
          );
        } else if (state.status == ProfileStatus.loaded &&
            state.profile != null) {
          // Fill form with Google user data
          setState(() {
            _fullNameController.text = state.profile!['name'] ?? '';
            _emailController.text = state.profile!['email'] ?? '';
            _companyNameController.text = state.profile!['comp_name'] ?? '';
            _phoneNumber = state.profile!['phone'] ?? '';
            _addressController.text = state.profile!['address'] ?? '';
            _apartmentController.text = state.profile!['address2'] ?? '';
            _cityController.text = state.profile!['city'] ?? '';
            _stateController.text = state.profile!['state'] ?? '';
            _zipCodeController.text = state.profile!['zip'] ?? '';
            _selectedCountry = state.profile!['country'] ?? '';
          });
        }

        /////////////Phone Number////////////////////

        String? initialValue = _phoneNumber;

        // // Parse initial value if it exists
        if (initialValue != null && initialValue.isNotEmpty) {
          // Try to extract country code and number
          // Most international numbers follow format +[country code][number]
          // We need to properly identify the country code part
          String countryCode = '+1'; // Default
          String number = '';

          var countryCodes = CountryCodes.countryCodes;
          // Find the matching country code
          for (String code in countryCodes) {
            if (initialValue.startsWith(code)) {
              countryCode = code;
              number = initialValue.substring(code.length);
              break;
            }
          }

          // If no match found, try a simple regex as fallback
          if (number.isEmpty && initialValue.startsWith('+')) {
            RegExp regex = RegExp(r'^\+(\d{1,3})(.*)$');
            var match = regex.firstMatch(initialValue);
            if (match != null && match.groupCount >= 2) {
              countryCode = '+${match.group(1)}';
              number = match.group(2) ?? '';
            } else {
              // If still no match, just use the whole string as number
              number = initialValue;
            }
          }

          initialCountryCode = countryCode;
          initialNumber = number;
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile Details')),
        body: SafeArea(
          child: ResponsivePadding(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 48 : 24,
                  horizontal: isTablet ? 48 : 0.0,
                ),
                constraints: BoxConstraints(
                  minHeight:
                      screenSize.height -
                      (MediaQuery.of(context).padding.top +
                          MediaQuery.of(context).padding.bottom +
                          kToolbarHeight),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   AppStrings.signUp,
                      //   style: Theme.of(context).textTheme.displayLarge,
                      // ),
                      const SizedBox(height: 22),
                      formLabel(AppStrings.fullName, isRequired: true),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.fullName,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Full Name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      formLabel(AppStrings.companyName, isRequired: true),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.companyName,
                        ),
                      ),
                      const SizedBox(height: 16),
                      formLabel(AppStrings.emailAddress, isRequired: true),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: AppStrings.emailAddress,
                        ),
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      formLabel(AppStrings.phoneNumber, isRequired: true),
                      SizedBox(height: 10),
                      _phoneNumber.isNotEmpty
                          ? _PhoneNumberField(
                            onPhoneNumberChanged: _handlePhoneNumberChange,
                            initialCountryCode: initialCountryCode,
                            initialNumber: initialNumber,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a phone number';
                              }
                              return null;
                            },
                          )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 24),
                      formLabel(AppStrings.address, isRequired: true),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _isPoBox ? 'PO Box' : 'Street Address',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Transform.scale(
                            scale:
                                0.8, // Increase/decrease this for custom size
                            child: Switch(
                              value: _isPoBox,
                              onChanged: (value) {
                                setState(() {
                                  _isPoBox = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _isPoBox
                          ? TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              hintText: 'Enter PO Box number',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'PO Box is required';
                              }
                              return null;
                            },
                          )
                          : AddressAutocomplete(
                            controller: _addressController,
                            onAddressSelected: _handleAddressSelected,
                            label: 'Address',
                            errorText: null,
                          ),
                      const SizedBox(height: 16),
                      formLabel(AppStrings.apartment),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _apartmentController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.apartment,
                        ),
                      ),
                      const SizedBox(height: 16),
                      formLabel(AppStrings.city, isRequired: true),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.city,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      formLabel(AppStrings.state, isRequired: true),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.state,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'State/Province is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      formLabel(AppStrings.zipCode, isRequired: true),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _zipCodeController,
                        decoration: const InputDecoration(
                          hintText: AppStrings.zipCode,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Zip/Postal Code is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      formLabel(AppStrings.country, isRequired: true),
                      SizedBox(height: 10),
                      _selectedCountry != null
                          ? CountryDropdown(
                            onCountrySelected: _handleCountrySelected,
                            initialCountryCode: _selectedCountry,
                            validator: (value) {
                              if (value == null) {
                                return 'Country is required';
                              }
                              return null;
                            },
                          )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 24),

                      // Text(
                      //   'Password ',
                      //   style: Theme.of(context).textTheme.titleMedium
                      //       ?.copyWith(fontWeight: FontWeight.bold),
                      // ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          formLabel(AppStrings.password, isRequired: false),
                          SizedBox(height: 10),
                          PasswordTextField(
                            svgPath: 'assets/icons/ic_password.svg',
                            label: AppStrings.password,
                            controller: _passwordController,
                            // validator: Validators.validatePassword,
                          ),
                          const SizedBox(height: 16),
                          formLabel(
                            AppStrings.confirmPassword,
                            isRequired: false,
                          ),
                          SizedBox(height: 10),
                          PasswordTextField(
                            svgPath: 'assets/icons/ic_password.svg',
                            label: 'Confirm Password',
                            controller: _confirmPasswordController,
                            validator:
                                _passwordController.text.isNotEmpty
                                    ? (value) =>
                                        Validators.validateConfirmPassword(
                                          value,
                                          _passwordController.text,
                                        )
                                    : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appButtonColor,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(AppStrings.updateProfile),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneNumberField extends StatefulWidget {
  final Function(String, String) onPhoneNumberChanged;
  final String? Function(String?)? validator;
  final String initialCountryCode;
  final String initialNumber;

  const _PhoneNumberField({
    super.key,
    required this.onPhoneNumberChanged,
    this.validator,
    required this.initialCountryCode,
    required this.initialNumber,
  });

  @override
  State<_PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<_PhoneNumberField> {
  final TextEditingController _controller = TextEditingController();
  late String _countryCode;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialNumber;
    _countryCode = widget.initialCountryCode;
  }

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
    // final supportedCountries =
    //     countries
    //         .where(
    //           (country) => country.dialCode.contains(country.code),
    //         )
    //         .toList();

    // Find the country code that matches our initial country code
    String initialCountryCode = 'US'; // Default fallback
    for (var country in countries) {
      if ('+${country.dialCode}' == _countryCode) {
        initialCountryCode = country.code;
        break;
      }
    }

    print(_controller);

    return IntlPhoneField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      initialCountryCode: initialCountryCode,
      // countries: supportedCountries,
      onChanged: (phone) {
        // Pass both country code and phone number to parent
        widget.onPhoneNumberChanged(phone.countryCode, phone.number);
      },
      onSaved: (phone) {
        widget.onPhoneNumberChanged(
          phone?.countryCode ?? '',
          phone?.number ?? '',
        );
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

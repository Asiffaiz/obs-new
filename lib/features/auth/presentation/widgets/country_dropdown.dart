import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';

class CountryDropdown extends StatefulWidget {
  final Function(String) onCountrySelected;
  final String? initialCountryCode;
  final String? Function(String?)? validator;

  const CountryDropdown({
    Key? key,
    required this.onCountrySelected,
    this.initialCountryCode,
    this.validator,
  }) : super(key: key);

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  late List<String> _countries;
  String? _selectedCountry;
  List<String> _filteredCountries = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _countries = countries.map((country) => country.name).toList();
    _filteredCountries = _countries;

    if (widget.initialCountryCode != null) {
      _selectedCountry = _countries.firstWhere(
        (country) => country == widget.initialCountryCode,
        orElse: () => _countries.first,
      );
    } else {
      // Default to first country (US) if none provided
      _selectedCountry = _countries.first;
    }

    // Invoke the callback with the initial country
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCountrySelected(_selectedCountry!);
    });
  }

  @override
  void didUpdateWidget(CountryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update selected country if initialCountryCode changed
    if (widget.initialCountryCode != oldWidget.initialCountryCode) {
      if (widget.initialCountryCode != null) {
        _selectedCountry = _countries.firstWhere(
          (country) => country == widget.initialCountryCode,
          orElse: () => _countries.first,
        );
      } else {
        _selectedCountry = _countries.first;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _countries;
      } else {
        _filteredCountries =
            _countries
                .where(
                  (country) =>
                      country.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size to limit dropdown height
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDropdownHeight = screenHeight * 0.4; // 40% of screen height

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isDropdownOpen = !_isDropdownOpen;
              if (_isDropdownOpen) {
                _searchController.clear();
                _filteredCountries = _countries;
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCountry ?? 'Country',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _selectedCountry != null
                              ? Colors.black87
                              : Colors.grey,
                    ),
                  ),
                ),
                Icon(
                  _isDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_isDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(maxHeight: maxDropdownHeight),
            child: Column(
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: _filterCountries,
                  ),
                ),
                // Country list
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      return ListTile(
                        title: Text(
                          country,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                            _isDropdownOpen = false;
                            _searchController.clear();
                            _filteredCountries = _countries;
                          });
                          widget.onCountrySelected(country);
                        },
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

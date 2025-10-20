import 'package:flutter/material.dart';

class Country {
  final String name;
  final String code;
  final String flagImage;
  final String dialCode;

  Country({
    required this.name,
    required this.code,
    required this.flagImage,
    required this.dialCode,
  });
}

class CountryPickerWidget extends StatefulWidget {
  final Function(Country) onCountrySelected;
  final Country initialCountry;

  const CountryPickerWidget({
    super.key,
    required this.onCountrySelected,
    required this.initialCountry,
  });

  @override
  State<CountryPickerWidget> createState() => _CountryPickerWidgetState();
}

class _CountryPickerWidgetState extends State<CountryPickerWidget> {
  late Country _selectedCountry;
  late TextEditingController _searchController;
  late List<Country> _countries;
  late List<Country> _filteredCountries;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _searchController = TextEditingController();
    _countries = _getCountries();
    _filteredCountries = List.from(_countries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Country> _getCountries() {
    // This is a simplified list with emoji flags instead of image assets
    return [
      Country(
        name: 'Afghanistan',
        code: 'AF',
        flagImage: '🇦🇫',
        dialCode: '+93',
      ),
      Country(name: 'Albania', code: 'AL', flagImage: '🇦🇱', dialCode: '+355'),
      Country(name: 'Algeria', code: 'DZ', flagImage: '🇩🇿', dialCode: '+213'),
      Country(
        name: 'American Samoa',
        code: 'AS',
        flagImage: '🇦🇸',
        dialCode: '+1684',
      ),
      Country(name: 'Andorra', code: 'AD', flagImage: '🇦🇩', dialCode: '+376'),
      Country(name: 'Angola', code: 'AO', flagImage: '🇦🇴', dialCode: '+244'),
      Country(
        name: 'Anguilla',
        code: 'AI',
        flagImage: '🇦🇮',
        dialCode: '+1264',
      ),
      Country(
        name: 'Antarctica',
        code: 'AQ',
        flagImage: '🇦🇶',
        dialCode: '+672',
      ),
      Country(name: 'Pakistan', code: 'PK', flagImage: '🇵🇰', dialCode: '+92'),
      // Add more countries as needed
    ];
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = List.from(_countries);
      } else {
        _filteredCountries =
            _countries
                .where(
                  (country) =>
                      country.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _showCountryPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search country',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _filterCountries,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: _filteredCountries.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Text(
                          country.flagImage,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      title: Text(country.name),
                      trailing: Text(
                        country.dialCode,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountry = country;
                        });
                        widget.onCountrySelected(country);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showCountryPickerDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Text(
                _selectedCountry.flagImage,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _selectedCountry.dialCode,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

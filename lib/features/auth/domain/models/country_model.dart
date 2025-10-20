class CountryModel {
  final String code;
  final String name;
  final String? flagEmoji;

  const CountryModel({required this.code, required this.name, this.flagEmoji});

  // Dummy country list for testing purposes
  static List<CountryModel> getDummyCountries() {
    return [
      const CountryModel(code: 'US', name: 'United States', flagEmoji: '🇺🇸'),
      const CountryModel(code: 'CA', name: 'Canada', flagEmoji: '🇨🇦'),
      const CountryModel(code: 'GB', name: 'United Kingdom', flagEmoji: '🇬🇧'),
      const CountryModel(code: 'AU', name: 'Australia', flagEmoji: '🇦🇺'),
      const CountryModel(code: 'DE', name: 'Germany', flagEmoji: '🇩🇪'),
      const CountryModel(code: 'FR', name: 'France', flagEmoji: '🇫🇷'),
      const CountryModel(code: 'JP', name: 'Japan', flagEmoji: '🇯🇵'),
      const CountryModel(code: 'IN', name: 'India', flagEmoji: '🇮🇳'),
      const CountryModel(code: 'BR', name: 'Brazil', flagEmoji: '🇧🇷'),
      const CountryModel(code: 'CN', name: 'China', flagEmoji: '🇨🇳'),
      const CountryModel(code: 'RU', name: 'Russia', flagEmoji: '🇷🇺'),
      const CountryModel(code: 'ZA', name: 'South Africa', flagEmoji: '🇿🇦'),
      const CountryModel(code: 'SA', name: 'Saudi Arabia', flagEmoji: '🇸🇦'),
      const CountryModel(
        code: 'AE',
        name: 'United Arab Emirates',
        flagEmoji: '🇦🇪',
      ),
      const CountryModel(code: 'PK', name: 'Pakistan', flagEmoji: '🇵🇰'),
      const CountryModel(code: 'SG', name: 'Singapore', flagEmoji: '🇸🇬'),
      const CountryModel(code: 'MY', name: 'Malaysia', flagEmoji: '🇲🇾'),
      const CountryModel(code: 'MX', name: 'Mexico', flagEmoji: '🇲🇽'),
      const CountryModel(code: 'IT', name: 'Italy', flagEmoji: '🇮🇹'),
      const CountryModel(code: 'ES', name: 'Spain', flagEmoji: '🇪🇸'),
    ];
  }
}

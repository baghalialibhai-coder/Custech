class CountryModel {
  final String name;
  final String code;
  final String currencyCode;
  final String currencySymbol;
  final String flag;
  final String dialCode;

  CountryModel({
    required this.name,
    required this.code,
    required this.currencyCode,
    required this.currencySymbol,
    required this.flag,
    required this.dialCode,
  });
}

class CountriesData {
  static final List<CountryModel> countries = [
    // ============================================================
    // 🌏 ASIA
    // ============================================================
    CountryModel(
      name: 'Pakistan',
      code: 'PK',
      currencyCode: 'PKR',
      currencySymbol: 'Rs',
      flag: '🇵🇰',
      dialCode: '+92',
    ),
    CountryModel(
      name: 'India',
      code: 'IN',
      currencyCode: 'INR',
      currencySymbol: '₹',
      flag: '🇮🇳',
      dialCode: '+91',
    ),
    CountryModel(
      name: 'China',
      code: 'CN',
      currencyCode: 'CNY',
      currencySymbol: '¥',
      flag: '🇨🇳',
      dialCode: '+86',
    ),
    CountryModel(
      name: 'Japan',
      code: 'JP',
      currencyCode: 'JPY',
      currencySymbol: '¥',
      flag: '🇯🇵',
      dialCode: '+81',
    ),
    CountryModel(
      name: 'South Korea',
      code: 'KR',
      currencyCode: 'KRW',
      currencySymbol: '₩',
      flag: '🇰🇷',
      dialCode: '+82',
    ),
    CountryModel(
      name: 'Indonesia',
      code: 'ID',
      currencyCode: 'IDR',
      currencySymbol: 'Rp',
      flag: '🇮🇩',
      dialCode: '+62',
    ),
    CountryModel(
      name: 'Malaysia',
      code: 'MY',
      currencyCode: 'MYR',
      currencySymbol: 'RM',
      flag: '🇲🇾',
      dialCode: '+60',
    ),
    CountryModel(
      name: 'Singapore',
      code: 'SG',
      currencyCode: 'SGD',
      currencySymbol: 'S\$',
      flag: '🇸🇬',
      dialCode: '+65',
    ),
    CountryModel(
      name: 'Thailand',
      code: 'TH',
      currencyCode: 'THB',
      currencySymbol: '฿',
      flag: '🇹🇭',
      dialCode: '+66',
    ),
    CountryModel(
      name: 'Vietnam',
      code: 'VN',
      currencyCode: 'VND',
      currencySymbol: '₫',
      flag: '🇻🇳',
      dialCode: '+84',
    ),
    CountryModel(
      name: 'Philippines',
      code: 'PH',
      currencyCode: 'PHP',
      currencySymbol: '₱',
      flag: '🇵🇭',
      dialCode: '+63',
    ),
    CountryModel(
      name: 'Bangladesh',
      code: 'BD',
      currencyCode: 'BDT',
      currencySymbol: '৳',
      flag: '🇧🇩',
      dialCode: '+880',
    ),
    CountryModel(
      name: 'Nepal',
      code: 'NP',
      currencyCode: 'NPR',
      currencySymbol: 'Rs',
      flag: '🇳🇵',
      dialCode: '+977',
    ),
    CountryModel(
      name: 'Sri Lanka',
      code: 'LK',
      currencyCode: 'LKR',
      currencySymbol: 'Rs',
      flag: '🇱🇰',
      dialCode: '+94',
    ),
    CountryModel(
      name: 'UAE',
      code: 'AE',
      currencyCode: 'AED',
      currencySymbol: 'د.إ',
      flag: '🇦🇪',
      dialCode: '+971',
    ),
    CountryModel(
      name: 'Saudi Arabia',
      code: 'SA',
      currencyCode: 'SAR',
      currencySymbol: '﷼',
      flag: '🇸🇦',
      dialCode: '+966',
    ),
    CountryModel(
      name: 'Turkey',
      code: 'TR',
      currencyCode: 'TRY',
      currencySymbol: '₺',
      flag: '🇹🇷',
      dialCode: '+90',
    ),
    CountryModel(
      name: 'Israel',
      code: 'IL',
      currencyCode: 'ILS',
      currencySymbol: '₪',
      flag: '🇮🇱',
      dialCode: '+972',
    ),

    // ============================================================
    // 🌎 NORTH AMERICA
    // ============================================================
    CountryModel(
      name: 'United States',
      code: 'US',
      currencyCode: 'USD',
      currencySymbol: '\$',
      flag: '🇺🇸',
      dialCode: '+1',
    ),
    CountryModel(
      name: 'Canada',
      code: 'CA',
      currencyCode: 'CAD',
      currencySymbol: 'C\$',
      flag: '🇨🇦',
      dialCode: '+1',
    ),
    CountryModel(
      name: 'Mexico',
      code: 'MX',
      currencyCode: 'MXN',
      currencySymbol: '\$',
      flag: '🇲🇽',
      dialCode: '+52',
    ),

    // ============================================================
    // 🌍 EUROPE
    // ============================================================
    CountryModel(
      name: 'United Kingdom',
      code: 'GB',
      currencyCode: 'GBP',
      currencySymbol: '£',
      flag: '🇬🇧',
      dialCode: '+44',
    ),
    CountryModel(
      name: 'Germany',
      code: 'DE',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇩🇪',
      dialCode: '+49',
    ),
    CountryModel(
      name: 'France',
      code: 'FR',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇫🇷',
      dialCode: '+33',
    ),
    CountryModel(
      name: 'Italy',
      code: 'IT',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇮🇹',
      dialCode: '+39',
    ),
    CountryModel(
      name: 'Spain',
      code: 'ES',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇪🇸',
      dialCode: '+34',
    ),
    CountryModel(
      name: 'Portugal',
      code: 'PT',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇵🇹',
      dialCode: '+351',
    ),
    CountryModel(
      name: 'Netherlands',
      code: 'NL',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇳🇱',
      dialCode: '+31',
    ),
    CountryModel(
      name: 'Belgium',
      code: 'BE',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇧🇪',
      dialCode: '+32',
    ),
    CountryModel(
      name: 'Switzerland',
      code: 'CH',
      currencyCode: 'CHF',
      currencySymbol: 'Fr',
      flag: '🇨🇭',
      dialCode: '+41',
    ),
    CountryModel(
      name: 'Sweden',
      code: 'SE',
      currencyCode: 'SEK',
      currencySymbol: 'kr',
      flag: '🇸🇪',
      dialCode: '+46',
    ),
    CountryModel(
      name: 'Norway',
      code: 'NO',
      currencyCode: 'NOK',
      currencySymbol: 'kr',
      flag: '🇳🇴',
      dialCode: '+47',
    ),
    CountryModel(
      name: 'Denmark',
      code: 'DK',
      currencyCode: 'DKK',
      currencySymbol: 'kr',
      flag: '🇩🇰',
      dialCode: '+45',
    ),
    CountryModel(
      name: 'Finland',
      code: 'FI',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇫🇮',
      dialCode: '+358',
    ),
    CountryModel(
      name: 'Ireland',
      code: 'IE',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇮🇪',
      dialCode: '+353',
    ),
    CountryModel(
      name: 'Austria',
      code: 'AT',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇦🇹',
      dialCode: '+43',
    ),
    CountryModel(
      name: 'Greece',
      code: 'GR',
      currencyCode: 'EUR',
      currencySymbol: '€',
      flag: '🇬🇷',
      dialCode: '+30',
    ),
    CountryModel(
      name: 'Poland',
      code: 'PL',
      currencyCode: 'PLN',
      currencySymbol: 'zł',
      flag: '🇵🇱',
      dialCode: '+48',
    ),
    CountryModel(
      name: 'Ukraine',
      code: 'UA',
      currencyCode: 'UAH',
      currencySymbol: '₴',
      flag: '🇺🇦',
      dialCode: '+380',
    ),
    CountryModel(
      name: 'Russia',
      code: 'RU',
      currencyCode: 'RUB',
      currencySymbol: '₽',
      flag: '🇷🇺',
      dialCode: '+7',
    ),

    // ============================================================
    // 🌎 SOUTH AMERICA
    // ============================================================
    CountryModel(
      name: 'Brazil',
      code: 'BR',
      currencyCode: 'BRL',
      currencySymbol: 'R\$',
      flag: '🇧🇷',
      dialCode: '+55',
    ),
    CountryModel(
      name: 'Argentina',
      code: 'AR',
      currencyCode: 'ARS',
      currencySymbol: '\$',
      flag: '🇦🇷',
      dialCode: '+54',
    ),
    CountryModel(
      name: 'Colombia',
      code: 'CO',
      currencyCode: 'COP',
      currencySymbol: '\$',
      flag: '🇨🇴',
      dialCode: '+57',
    ),
    CountryModel(
      name: 'Chile',
      code: 'CL',
      currencyCode: 'CLP',
      currencySymbol: '\$',
      flag: '🇨🇱',
      dialCode: '+56',
    ),
    CountryModel(
      name: 'Peru',
      code: 'PE',
      currencyCode: 'PEN',
      currencySymbol: 'S/',
      flag: '🇵🇪',
      dialCode: '+51',
    ),

    // ============================================================
    // 🌍 AFRICA
    // ============================================================
    CountryModel(
      name: 'Nigeria',
      code: 'NG',
      currencyCode: 'NGN',
      currencySymbol: '₦',
      flag: '🇳🇬',
      dialCode: '+234',
    ),
    CountryModel(
      name: 'South Africa',
      code: 'ZA',
      currencyCode: 'ZAR',
      currencySymbol: 'R',
      flag: '🇿🇦',
      dialCode: '+27',
    ),
    CountryModel(
      name: 'Egypt',
      code: 'EG',
      currencyCode: 'EGP',
      currencySymbol: 'E£',
      flag: '🇪🇬',
      dialCode: '+20',
    ),
    CountryModel(
      name: 'Kenya',
      code: 'KE',
      currencyCode: 'KES',
      currencySymbol: 'KSh',
      flag: '🇰🇪',
      dialCode: '+254',
    ),
    CountryModel(
      name: 'Ghana',
      code: 'GH',
      currencyCode: 'GHS',
      currencySymbol: '₵',
      flag: '🇬🇭',
      dialCode: '+233',
    ),
    CountryModel(
      name: 'Morocco',
      code: 'MA',
      currencyCode: 'MAD',
      currencySymbol: 'د.م.',
      flag: '🇲🇦',
      dialCode: '+212',
    ),

    // ============================================================
    // 🌏 OCEANIA
    // ============================================================
    CountryModel(
      name: 'Australia',
      code: 'AU',
      currencyCode: 'AUD',
      currencySymbol: 'A\$',
      flag: '🇦🇺',
      dialCode: '+61',
    ),
    CountryModel(
      name: 'New Zealand',
      code: 'NZ',
      currencyCode: 'NZD',
      currencySymbol: 'NZ\$',
      flag: '🇳🇿',
      dialCode: '+64',
    ),
  ];

  // ✅ Get country by code
  static CountryModel? getCountryByCode(String code) {
    try {
      return countries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  // ✅ Get currency symbol by country code
  static String getCurrencySymbol(String countryCode) {
    final country = getCountryByCode(countryCode);
    return country?.currencySymbol ?? '\$';
  }

  // ✅ Get currency code by country code
  static String getCurrencyCode(String countryCode) {
    final country = getCountryByCode(countryCode);
    return country?.currencyCode ?? 'USD';
  }

  // ✅ Search countries
  static List<CountryModel> searchCountries(String query) {
    if (query.isEmpty) return countries;
    return countries.where((country) =>
    country.name.toLowerCase().contains(query.toLowerCase()) ||
        country.code.toLowerCase().contains(query.toLowerCase()) ||
        country.currencyCode.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
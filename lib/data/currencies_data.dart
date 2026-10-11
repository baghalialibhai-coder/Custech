import '../core/models/currency_model.dart';

class CurrenciesData {
  static final List<CurrencyModel> currencies = [
    // ============================================================
    //  🌏 ASIA
    // ============================================================
    CurrencyModel(
      code: 'PKR',
      symbol: 'Rs',
      name: 'Pakistani Rupee',
      countryCode: 'PK',
      flag: '🇵🇰',
    ),
    CurrencyModel(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee',
      countryCode: 'IN',
      flag: '🇮🇳',
    ),
    CurrencyModel(
      code: 'AED',
      symbol: 'د.إ',
      name: 'UAE Dirham',
      countryCode: 'AE',
      flag: '🇦🇪',
    ),
    CurrencyModel(
      code: 'SAR',
      symbol: '﷼',
      name: 'Saudi Riyal',
      countryCode: 'SA',
      flag: '🇸🇦',
    ),
    CurrencyModel(
      code: 'TRY',
      symbol: '₺',
      name: 'Turkish Lira',
      countryCode: 'TR',
      flag: '🇹🇷',
    ),
    CurrencyModel(
      code: 'BDT',
      symbol: '৳',
      name: 'Bangladeshi Taka',
      countryCode: 'BD',
      flag: '🇧🇩',
    ),
    CurrencyModel(
      code: 'CNY',
      symbol: '¥',
      name: 'Chinese Yuan',
      countryCode: 'CN',
      flag: '🇨🇳',
    ),
    CurrencyModel(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      countryCode: 'JP',
      flag: '🇯🇵',
    ),
    CurrencyModel(
      code: 'KRW',
      symbol: '₩',
      name: 'South Korean Won',
      countryCode: 'KR',
      flag: '🇰🇷',
    ),
    CurrencyModel(
      code: 'IDR',
      symbol: 'Rp',
      name: 'Indonesian Rupiah',
      countryCode: 'ID',
      flag: '🇮🇩',
    ),
    CurrencyModel(
      code: 'MYR',
      symbol: 'RM',
      name: 'Malaysian Ringgit',
      countryCode: 'MY',
      flag: '🇲🇾',
    ),
    CurrencyModel(
      code: 'SGD',
      symbol: 'S\$',
      name: 'Singapore Dollar',
      countryCode: 'SG',
      flag: '🇸🇬',
    ),
    CurrencyModel(
      code: 'THB',
      symbol: '฿',
      name: 'Thai Baht',
      countryCode: 'TH',
      flag: '🇹🇭',
    ),
    CurrencyModel(
      code: 'VND',
      symbol: '₫',
      name: 'Vietnamese Dong',
      countryCode: 'VN',
      flag: '🇻🇳',
    ),
    CurrencyModel(
      code: 'PHP',
      symbol: '₱',
      name: 'Philippine Peso',
      countryCode: 'PH',
      flag: '🇵🇭',
    ),
    CurrencyModel(
      code: 'NPR',
      symbol: 'Rs',
      name: 'Nepalese Rupee',
      countryCode: 'NP',
      flag: '🇳🇵',
    ),
    CurrencyModel(
      code: 'LKR',
      symbol: 'Rs',
      name: 'Sri Lankan Rupee',
      countryCode: 'LK',
      flag: '🇱🇰',
    ),

    // ============================================================
    //  🌎 NORTH AMERICA
    // ============================================================
    CurrencyModel(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
      countryCode: 'US',
      flag: '🇺🇸',
    ),
    CurrencyModel(
      code: 'CAD',
      symbol: 'C\$',
      name: 'Canadian Dollar',
      countryCode: 'CA',
      flag: '🇨🇦',
    ),
    CurrencyModel(
      code: 'MXN',
      symbol: '\$',
      name: 'Mexican Peso',
      countryCode: 'MX',
      flag: '🇲🇽',
    ),

    // ============================================================
    //  🌍 EUROPE
    // ============================================================
    CurrencyModel(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      countryCode: 'EU',
      flag: '🇪🇺',
    ),
    CurrencyModel(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      countryCode: 'GB',
      flag: '🇬🇧',
    ),
    CurrencyModel(
      code: 'CHF',
      symbol: 'Fr',
      name: 'Swiss Franc',
      countryCode: 'CH',
      flag: '🇨🇭',
    ),
    CurrencyModel(
      code: 'SEK',
      symbol: 'kr',
      name: 'Swedish Krona',
      countryCode: 'SE',
      flag: '🇸🇪',
    ),
    CurrencyModel(
      code: 'NOK',
      symbol: 'kr',
      name: 'Norwegian Krone',
      countryCode: 'NO',
      flag: '🇳🇴',
    ),
    CurrencyModel(
      code: 'DKK',
      symbol: 'kr',
      name: 'Danish Krone',
      countryCode: 'DK',
      flag: '🇩🇰',
    ),
    CurrencyModel(
      code: 'PLN',
      symbol: 'zł',
      name: 'Polish Zloty',
      countryCode: 'PL',
      flag: '🇵🇱',
    ),
    CurrencyModel(
      code: 'UAH',
      symbol: '₴',
      name: 'Ukrainian Hryvnia',
      countryCode: 'UA',
      flag: '🇺🇦',
    ),
    CurrencyModel(
      code: 'RUB',
      symbol: '₽',
      name: 'Russian Ruble',
      countryCode: 'RU',
      flag: '🇷🇺',
    ),

    // ============================================================
    //  🌎 SOUTH AMERICA
    // ============================================================
    CurrencyModel(
      code: 'BRL',
      symbol: 'R\$',
      name: 'Brazilian Real',
      countryCode: 'BR',
      flag: '🇧🇷',
    ),
    CurrencyModel(
      code: 'ARS',
      symbol: '\$',
      name: 'Argentine Peso',
      countryCode: 'AR',
      flag: '🇦🇷',
    ),
    CurrencyModel(
      code: 'COP',
      symbol: '\$',
      name: 'Colombian Peso',
      countryCode: 'CO',
      flag: '🇨🇴',
    ),
    CurrencyModel(
      code: 'CLP',
      symbol: '\$',
      name: 'Chilean Peso',
      countryCode: 'CL',
      flag: '🇨🇱',
    ),
    CurrencyModel(
      code: 'PEN',
      symbol: 'S/',
      name: 'Peruvian Sol',
      countryCode: 'PE',
      flag: '🇵🇪',
    ),

    // ============================================================
    //  🌍 AFRICA
    // ============================================================
    CurrencyModel(
      code: 'NGN',
      symbol: '₦',
      name: 'Nigerian Naira',
      countryCode: 'NG',
      flag: '🇳🇬',
    ),
    CurrencyModel(
      code: 'ZAR',
      symbol: 'R',
      name: 'South African Rand',
      countryCode: 'ZA',
      flag: '🇿🇦',
    ),
    CurrencyModel(
      code: 'EGP',
      symbol: 'E£',
      name: 'Egyptian Pound',
      countryCode: 'EG',
      flag: '🇪🇬',
    ),
    CurrencyModel(
      code: 'KES',
      symbol: 'KSh',
      name: 'Kenyan Shilling',
      countryCode: 'KE',
      flag: '🇰🇪',
    ),
    CurrencyModel(
      code: 'GHS',
      symbol: '₵',
      name: 'Ghanaian Cedi',
      countryCode: 'GH',
      flag: '🇬🇭',
    ),
    CurrencyModel(
      code: 'MAD',
      symbol: 'د.م.',
      name: 'Moroccan Dirham',
      countryCode: 'MA',
      flag: '🇲🇦',
    ),

    // ============================================================
    //  🌏 OCEANIA
    // ============================================================
    CurrencyModel(
      code: 'AUD',
      symbol: 'A\$',
      name: 'Australian Dollar',
      countryCode: 'AU',
      flag: '🇦🇺',
    ),
    CurrencyModel(
      code: 'NZD',
      symbol: 'NZ\$',
      name: 'New Zealand Dollar',
      countryCode: 'NZ',
      flag: '🇳🇿',
    ),
  ];

  // Get currency by code
  static CurrencyModel? getCurrencyByCode(String code) {
    try {
      return currencies.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }

  // Get currency by country code
  static CurrencyModel? getCurrencyByCountryCode(String countryCode) {
    try {
      return currencies.firstWhere((currency) => currency.countryCode == countryCode);
    } catch (e) {
      return null;
    }
  }

  // Search currencies
  static List<CurrencyModel> searchCurrencies(String query) {
    if (query.isEmpty) return currencies;
    return currencies.where((currency) =>
    currency.name.toLowerCase().contains(query.toLowerCase()) ||
        currency.code.toLowerCase().contains(query.toLowerCase()) ||
        currency.countryCode.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
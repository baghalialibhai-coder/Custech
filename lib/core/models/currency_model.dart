class CurrencyModel {
  final String code; // Currency code (e.g., PKR, USD, EUR)
  final String symbol; // Currency symbol (e.g., Rs, $, €)
  final String name; // Currency name (e.g., Pakistani Rupee)
  final String countryCode; // Associated country code
  final String flag; // Country flag emoji

  CurrencyModel({
    required this.code,
    required this.symbol,
    required this.name,
    required this.countryCode,
    required this.flag,
  });

  @override
  String toString() => '$flag $code ($symbol)';
}
class CountryModel {
  final String name;
  final String code; // Country code (e.g., PK, US)
  final String dialCode; // Phone code (e.g., +92, +1)
  final String flag; // Unicode flag emoji
  final int? minLength; // Minimum phone number length
  final int? maxLength; // Maximum phone number length

  CountryModel({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    this.minLength,
    this.maxLength,
  });

  @override
  String toString() => '$flag $name ($dialCode)';
}
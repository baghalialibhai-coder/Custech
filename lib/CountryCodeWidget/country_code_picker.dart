import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/country_model.dart';
import '../countriesPhoneNumberCode/countries_data.dart';


class CountryCodePicker extends StatefulWidget {
  final CountryModel? selectedCountry;
  final ValueChanged<CountryModel> onCountrySelected;
  final String? labelText;
  final String? hintText;
  final TextStyle? textStyle;
  final Color? borderColor;
  final double? borderRadius;

  const CountryCodePicker({
    super.key,
    this.selectedCountry,
    required this.onCountrySelected,
    this.labelText,
    this.hintText,
    this.textStyle,
    this.borderColor,
    this.borderRadius = 12,
  });

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  late CountryModel _selectedCountry;

  @override
  void initState() {
    super.initState();
    // Set default country (Pakistan) if none selected
    _selectedCountry = widget.selectedCountry ??
        CountriesData.countries.firstWhere(
              (c) => c.code == 'PK',
          orElse: () => CountriesData.countries.first,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A237E),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.borderColor ?? Colors.grey[300]!,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius!),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                // Flag
                Text(
                  _selectedCountry.flag,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                // Dial Code
                Text(
                  _selectedCountry.dialCode,
                  style: widget.textStyle ??
                      GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(width: 8),
                // Country Name
                Expanded(
                  child: Text(
                    _selectedCountry.name,
                    style: widget.textStyle ??
                        GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Dropdown Icon
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CountryPickerSheet(
        selectedCountry: _selectedCountry,
        onCountrySelected: (country) {
          setState(() {
            _selectedCountry = country;
          });
          widget.onCountrySelected(country);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ========== COUNTRY PICKER SHEET ==========
class CountryPickerSheet extends StatefulWidget {
  final CountryModel selectedCountry;
  final ValueChanged<CountryModel> onCountrySelected;

  const CountryPickerSheet({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryModel> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = CountriesData.countries;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Select Country',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCountries,
              decoration: InputDecoration(
                hintText: 'Search country...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Country List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;

                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 30),
                  ),
                  title: Text(
                    country.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF1A237E) : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    country.dialCode,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                    Icons.check_circle,
                    color: const Color(0xFF1A237E),
                    size: 24,
                  )
                      : null,
                  onTap: () => widget.onCountrySelected(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = CountriesData.countries;
      } else {
        _filteredCountries = CountriesData.countries.where((country) {
          final name = country.name.toLowerCase();
          final dialCode = country.dialCode;
          final code = country.code.toLowerCase();
          final search = query.toLowerCase();
          return name.contains(search) ||
              dialCode.contains(search) ||
              code.contains(search);
        }).toList();
      }
    });
  }
}
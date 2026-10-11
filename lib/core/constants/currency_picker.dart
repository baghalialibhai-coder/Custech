import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/currencies_data.dart';
import '../models/currency_model.dart';

class CurrencyPicker extends StatefulWidget {
  final CurrencyModel? selectedCurrency;
  final ValueChanged<CurrencyModel> onCurrencySelected;

  const CurrencyPicker({
    super.key,
    this.selectedCurrency,
    required this.onCurrencySelected,
  });

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<CurrencyPicker> {
  late CurrencyModel _selectedCurrency;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.selectedCurrency ??
        CurrenciesData.getCurrencyByCode('PKR') ??
        CurrenciesData.currencies.first;
  }

  @override
  void didUpdateWidget(CurrencyPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Update when parent changes selected currency
    if (widget.selectedCurrency != null &&
        widget.selectedCurrency!.code != _selectedCurrency.code) {
      setState(() {
        _selectedCurrency = widget.selectedCurrency!;
      });
    }
  }

  List<CurrencyModel> get _filteredCurrencies {
    if (_searchQuery.isEmpty) return CurrenciesData.currencies;
    return CurrenciesData.searchCurrencies(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showCurrencyPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCurrency.flag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCurrency.code,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  Text(
                    _selectedCurrency.symbol,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String localSearchQuery = '';

            List<CurrencyModel> getFilteredCurrencies() {
              if (localSearchQuery.isEmpty) return CurrenciesData.currencies;
              return CurrenciesData.searchCurrencies(localSearchQuery);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
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
                  Text(
                    'Select Currency',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          localSearchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search currency...',
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: getFilteredCurrencies().length,
                      itemBuilder: (context, index) {
                        final currency = getFilteredCurrencies()[index];
                        final isSelected = currency.code == _selectedCurrency.code;

                        return ListTile(
                          leading: Text(
                            currency.flag,
                            style: const TextStyle(fontSize: 30),
                          ),
                          title: Text(
                            currency.code,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? const Color(0xFF1A237E) : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '${currency.name} (${currency.symbol})',
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
                          onTap: () {
                            // ✅ Update selected currency
                            _selectedCurrency = currency;

                            // ✅ Call parent callback
                            widget.onCurrencySelected(currency);

                            // ✅ Close bottom sheet
                            Navigator.pop(context);

                            // ✅ Force rebuild
                            setState(() {});
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
      },
    );
  }
}
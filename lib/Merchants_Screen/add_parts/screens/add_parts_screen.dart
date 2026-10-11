// lib/Merchants_Screen/add_parts/screens/add_parts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/add_parts_provider.dart';
import '../../../languages/localization/app_localizations.dart';
import '../../../languages/widget/language_selection_screen.dart';

class AddPartsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? merchantData;

  const AddPartsScreen({
    super.key,
    this.merchantData,
  });

  @override
  ConsumerState<AddPartsScreen> createState() => _AddPartsScreenState();
}

class _AddPartsScreenState extends ConsumerState<AddPartsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _storeNameController;
  late TextEditingController _categoryController;
  late TextEditingController _itemsController;
  final _descriptionController = TextEditingController();

  String _selectedLanguage = 'English';
  int _selectedWordCount = 250;

  final List<String> _languages = [
    'English',
    'Urdu',
    'Arabic',
    'Hindi',
    'Spanish',
    'French',
    'Chinese',
    'Turkish',
    'Indonesian',
    'Malay'
  ];

  final Map<int, String> _wordCountOptions = {
    100: '100 Words (Short Summary)',
    250: '250 Words (Standard Detail)',
    500: '500 Words (Full Category List)',
    1000: '1,000 Words (Complete Catalog)',
    2000: '2,000 Words (Comprehensive Guide)',
  };

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(
      text: widget.merchantData?['shopName'] ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.merchantData?['shopType'] ?? '',
    );
    _itemsController = TextEditingController(
      text: widget.merchantData?['productsOverview'] ?? '',
    );
    _descriptionController.text = widget.merchantData?['storeDescription'] ?? '';
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _categoryController.dispose();
    _itemsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getCurrentLanguageName() {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final languageNames = {
      'en': 'English',
      'ur': 'اردو',
      'ar': 'العربية',
      'hi': 'हिन्दी',
      'es': 'Español',
      'fr': 'Français',
      'zh': '中文',
      'tr': 'Türkçe',
      'id': 'Bahasa Indonesia',
      'ms': 'Bahasa Melayu',
    };
    return languageNames[languageCode] ?? 'English';
  }

  void _generateWithAI() {
    final storeName = _storeNameController.text.trim();
    if (storeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Shop / Store Name first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ref.read(addPartsProvider.notifier).generateDescriptionWithAI(
          storeName: storeName,
          category: _categoryController.text.trim(),
          itemsOverview: _itemsController.text.trim(),
          language: _selectedLanguage,
          wordCount: _selectedWordCount,
        );
  }

  Future<void> _saveStoreProducts() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(addPartsProvider.notifier).saveStoreProductsToFirestore(
          storeName: _storeNameController.text.trim(),
          category: _categoryController.text.trim(),
          itemsOverview: _itemsController.text.trim(),
          description: _descriptionController.text.trim(),
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store products description saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final state = ref.read(addPartsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: ${state.error ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addPartsProvider);

    ref.listen<AddPartsState>(addPartsProvider, (previous, next) {
      if (next.generatedDescription.isNotEmpty &&
          next.generatedDescription != _descriptionController.text) {
        _descriptionController.text = next.generatedDescription;
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          context.tr('addParts'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _getCurrentLanguageName(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF388E3C)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 24,
                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store Products & AI Catalog',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Generates complete category itemized details based on word limit.',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Shop / Store Name
              _buildInputField(
                controller: _storeNameController,
                label: 'Shop / Store Name',
                hint: 'e.g. Unique Electronics / Karyana Store / Mobile Parts',
                icon: Icons.store,
                validator: (v) => v!.isEmpty ? 'Please enter shop name' : null,
              ),
              const SizedBox(height: 16),

              // 2. Business / Product Category
              _buildInputField(
                controller: _categoryController,
                label: 'Shop Category / Type (e.g. Mobile Parts, Grocery, Auto Parts)',
                hint: 'e.g. Mobile Parts, Grocery / Karyana, Auto Spare Parts',
                icon: Icons.category,
              ),
              const SizedBox(height: 16),

              // 3. Products / Items Available
              _buildInputField(
                controller: _itemsController,
                label: 'Specific Items / Brands (Optional)',
                hint: 'e.g. Samsung, iPhone screens, Shampoo, Rice, Oil, Compressors...',
                icon: Icons.shopping_bag,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // AI Controls Row: Language & Word Count Dropdowns
              Row(
                children: [
                  // Language Selector
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Language', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              isExpanded: true,
                              items: _languages
                                  .map((lang) => DropdownMenuItem(
                                        value: lang,
                                        child: Text(lang, style: const TextStyle(fontSize: 13)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedLanguage = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Word Count / Length Selector
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detail Length (Words)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedWordCount,
                              isExpanded: true,
                              items: _wordCountOptions.entries
                                  .map((entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedWordCount = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // "Write with AI" Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: state.isGenerating ? null : _generateWithAI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: state.isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    state.isGenerating ? 'Writing Catalog with AI...' : 'Write Catalog with AI',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Generated Description (Editable)
              Text(
                'Store Catalog Description (Editable)',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _descriptionController,
                maxLines: 10,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Press "Write Catalog with AI" to generate full category itemized list, or type manually...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: state.isSaving ? null : _saveStoreProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: state.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    state.isSaving ? 'Saving...' : 'Save Store Catalog',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.indigo, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

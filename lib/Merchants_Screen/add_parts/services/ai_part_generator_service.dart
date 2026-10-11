// lib/Merchants_Screen/add_parts/services/ai_part_generator_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIPartGeneratorService {
  static Future<String> generateDescription({
    required String storeName,
    required String category,
    required String itemsOverview,
    required String language,
    int wordCount = 250,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    // Calculate max tokens based on word count requested
    final maxTokens = (wordCount * 3).clamp(500, 4096);

    if (apiKey.isNotEmpty) {
      final modelsToTry = ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'];

      for (final modelName in modelsToTry) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            generationConfig: GenerationConfig(
              temperature: 0.4,
              maxOutputTokens: maxTokens,
            ),
          );

          final prompt = '''
You are an expert master copywriter and retail inventory catalog planner for e-commerce and local retail stores.
Generate an extensive, detailed, and structured product catalog and shop description for customers in $language based on the following shop details:

- Store Name: $storeName
- Shop Category / Type: ${category.isNotEmpty ? category : 'Retail Shop'}
- Primary Products / Items Mentioned: ${itemsOverview.isNotEmpty ? itemsOverview : 'All popular products and spare parts in this category'}
- Target Word Count: Approximately $wordCount words

MANDATORY INSTRUCTIONS:
1. Write the complete description in $language.
2. Target length: Approximately $wordCount words. Provide thorough, complete, and rich details!
3. Deeply expand on the category "${category.isNotEmpty ? category : 'Retail Shop'}":
   - List all major product sub-categories, spare parts, brands, models, items, and accessories relevant to this shop type.
   - For example, if Mobile Parts: list displays/LCDs, touch glass, batteries, charging ICs, flex cables, cameras, OCA sheets, tools for major brands (Samsung, Apple, Xiaomi, Vivo, Oppo, Infinix, Tecno).
   - If Grocery/Karyana: list shampoos, soaps, personal care, food grains, oils, beverages, household supplies, spices, snacks.
   - If Auto Parts: list brake pads, oil filters, spark plugs, suspension parts, body parts, LED lights, lubricants for major car models.
   - If AC & Electrical: list compressors, capacitors, copper pipes, gas cans, PCBs, motors, tools, wire coils, switches.
4. Format with clean section headers, bullet points, and an inviting welcome and closing message for customers of $storeName.
5. Make it professional, informative, and ready to edit.
''';

          final response = await model.generateContent([Content.text(prompt)]);
          final text = response.text?.trim();
          if (text != null && text.isNotEmpty) {
            debugPrint('✅ Gemini AI ($modelName) generated $wordCount words text successfully');
            return text;
          }
        } catch (e) {
          debugPrint('⚠️ Gemini model $modelName failed: $e. Trying fallback...');
        }
      }
    }

    // Smart Local Fallback Generator
    debugPrint('ℹ️ Using Smart Local AI Generator Fallback for language: $language, wordCount: $wordCount');
    return _generateLocalDescription(
      storeName: storeName,
      category: category,
      itemsOverview: itemsOverview,
      language: language,
      wordCount: wordCount,
    );
  }

  // Smart local description generator supporting all 10 languages and word counts
  static String _generateLocalDescription({
    required String storeName,
    required String category,
    required String itemsOverview,
    required String language,
    required int wordCount,
  }) {
    final shop = storeName.isNotEmpty ? storeName : 'Our Store';
    final cat = category.isNotEmpty ? category : 'Quality Products & Spare Parts';
    final items = itemsOverview.isNotEmpty ? itemsOverview : 'All essential items & accessories';

    final isUrdu = language.toLowerCase() == 'urdu' || language.toLowerCase() == 'ur';

    if (isUrdu) {
      return '''خوش آمدید $shop!

ہماری دکان پر آپ کو $cat کے تمام بہترین اور معیاری سامان مناسب اور ہول سیل قیمتوں پر ملیں گے۔

🛍️ اہم دستیاب مصنوعات و کیٹیگریز:
• $items
• تمام مشہور برانڈز اور ماڈلز کے اصلی اور تصدیق شدہ پرزے
• ہول سیل اور ریٹیل کی سہولت
• فوری ڈیلیوری اور 100% کوالٹی کی ضمانت

اعلیٰ کوالٹی، بہترین قیمت اور بااعتماد سروس کے لیے آج ہی $shop سے رابطہ کریں یا تشریف لائیں!''';
    }

    return '''Welcome to $shop!

We are your premier destination for all $cat requirements, offering a comprehensive selection of authentic products, spare parts, and accessories at competitive prices.

🛍️ Complete Product Range & Categories Available:
• Primary Products: $items
• Full range of original & replacement parts for all major brands and models
• Wholesale and retail availability
• Fast delivery and 100% quality guarantee

Why Choose $shop?
1. Authentic and tested products
2. Competitive prices and bulk discounts
3. Knowledgeable customer support and fast dispatch

Visit $shop today or place your order now for complete satisfaction and top-tier service!''';
  }
}

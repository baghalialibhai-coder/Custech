// lib/Merchants_Screen/add_parts/providers/add_parts_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_part_generator_service.dart';

class AddPartsState {
  final bool isGenerating;
  final bool isSaving;
  final String generatedDescription;
  final String? error;

  AddPartsState({
    this.isGenerating = false,
    this.isSaving = false,
    this.generatedDescription = '',
    this.error,
  });

  AddPartsState copyWith({
    bool? isGenerating,
    bool? isSaving,
    String? generatedDescription,
    String? error,
  }) {
    return AddPartsState(
      isGenerating: isGenerating ?? this.isGenerating,
      isSaving: isSaving ?? this.isSaving,
      generatedDescription: generatedDescription ?? this.generatedDescription,
      error: error,
    );
  }
}

class AddPartsNotifier extends Notifier<AddPartsState> {
  @override
  AddPartsState build() {
    return AddPartsState();
  }

  void updateDescription(String desc) {
    state = state.copyWith(generatedDescription: desc);
  }

  Future<void> generateDescriptionWithAI({
    required String storeName,
    required String category,
    required String itemsOverview,
    required String language,
    int wordCount = 250,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final desc = await AIPartGeneratorService.generateDescription(
        storeName: storeName,
        category: category,
        itemsOverview: itemsOverview,
        language: language,
        wordCount: wordCount,
      );
      state = state.copyWith(isGenerating: false, generatedDescription: desc);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  Future<bool> saveStoreProductsToFirestore({
    required String storeName,
    required String category,
    required String itemsOverview,
    required String description,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance.collection('merchants').doc(user.uid).set({
        'shopName': storeName,
        'shopType': category,
        'productsOverview': itemsOverview,
        'storeDescription': description,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final addPartsProvider = NotifierProvider<AddPartsNotifier, AddPartsState>(() {
  return AddPartsNotifier();
});

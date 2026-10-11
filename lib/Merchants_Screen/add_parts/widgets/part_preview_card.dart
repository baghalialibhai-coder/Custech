// lib/Merchants_Screen/add_parts/widgets/part_preview_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PartPreviewCard extends StatelessWidget {
  final String storeName;
  final String partName;
  final String brand;
  final String compatibility;
  final double price;
  final int stock;
  final String category;
  final String description;
  final List<File> imageFiles;

  const PartPreviewCard({
    super.key,
    required this.storeName,
    required this.partName,
    required this.brand,
    required this.compatibility,
    required this.price,
    required this.stock,
    required this.category,
    required this.description,
    this.imageFiles = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Store Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.indigo,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      storeName.isNotEmpty ? storeName : 'My Store',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category.isNotEmpty ? category : 'Spare Part',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Image preview or placeholder
          if (imageFiles.isNotEmpty)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.file(imageFiles.first, fit: BoxFit.cover),
            )
          else
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.grey[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.precision_manufacturing, size: 48, color: Colors.indigo[300]),
                  const SizedBox(height: 6),
                  Text(
                    'No Image Added',
                    style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partName.isNotEmpty ? partName : 'Spare Part Name',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    if (brand.isNotEmpty) ...[
                      Chip(
                        avatar: const Icon(Icons.branding_watermark, size: 16),
                        label: Text(brand, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.indigo[50],
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (compatibility.isNotEmpty)
                      Expanded(
                        child: Chip(
                          avatar: const Icon(Icons.directions_car, size: 16),
                          label: Text(
                            'Fits: $compatibility',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.green[50],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price & Stock Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PKR ${price.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    Text(
                      stock > 0 ? 'In Stock ($stock)' : 'Out of Stock',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: stock > 0 ? Colors.indigo : Colors.red,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Description
                Text(
                  'Description (AI Generated)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description.isNotEmpty
                      ? description
                      : 'Fill in part facts and tap "Write with AI" to generate description.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

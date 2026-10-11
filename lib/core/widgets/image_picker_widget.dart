import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_storage_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(String? imageUrl) onImageUploaded;
  final String? existingImageUrl;
  final double? height;
  final double? width;
  final bool showDeleteButton;

  const ImagePickerWidget({
    super.key,
    required this.onImageUploaded,
    this.existingImageUrl,
    this.height,
    this.width,
    this.showDeleteButton = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.existingImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height ?? 120;
    final width = widget.width ?? double.infinity;

    return Column(
      children: [
        // ✅ Image Display
        Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _imageUrl != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
                if (widget.showDeleteButton)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      radius: 16,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: () {
                          setState(() {
                            _imageUrl = null;
                          });
                          widget.onImageUploaded(null);
                        },
                      ),
                    ),
                  ),
                if (_isUploading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Uploading...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 40,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to add image',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ✅ Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gallery Button
            _buildActionButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: _pickFromGallery,
            ),
            const SizedBox(width: 12),

            // Camera Button
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              onTap: _pickFromCamera,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: _isUploading ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: const Color(0xFF1A237E),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ PICK FROM GALLERY
  // ============================================================
  Future<void> _pickFromGallery() async {
    final file = await FirebaseStorageService.pickImageFromGallery();
    if (file != null) {
      await _uploadFile(file);
    }
  }

  // ============================================================
  // ✅ PICK FROM CAMERA
  // ============================================================
  Future<void> _pickFromCamera() async {
    final file = await FirebaseStorageService.pickImageFromCamera();
    if (file != null) {
      await _uploadFile(file);
    }
  }

  // ============================================================
  // ✅ UPLOAD FILE
  // ============================================================
  Future<void> _uploadFile(File file) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final imageUrl = await FirebaseStorageService.uploadImage(file);

      setState(() {
        _isUploading = false;
        if (imageUrl != null) {
          _imageUrl = imageUrl;
          widget.onImageUploaded(imageUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
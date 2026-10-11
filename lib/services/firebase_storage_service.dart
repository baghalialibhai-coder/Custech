// lib/services/firebase_storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============================================================
  // ✅ SINGLE IMAGE UPLOAD
  // ============================================================
  static Future<String?> uploadImage(File image, {String folder = 'images'}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final ref = _storage.ref().child('uploads/$userId/$folder/$fileName');

      final uploadTask = await ref.putFile(
        image,
        SettableMetadata(contentType: _getMimeType(image.path, 'image/jpeg')),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Firebase Storage upload success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Firebase Storage image upload error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ AUDIO UPLOAD (Voice Messages)
  // ============================================================
  static Future<String?> uploadAudio(File audioFile, {String folder = 'audios'}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(audioFile.path)}';
      final ref = _storage.ref().child('uploads/$userId/$folder/$fileName');

      final uploadTask = await ref.putFile(
        audioFile,
        SettableMetadata(contentType: _getMimeType(audioFile.path, 'audio/mpeg')),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Firebase Storage audio upload success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Firebase Storage audio upload error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ VIDEO UPLOAD
  // ============================================================
  static Future<String?> uploadVideo(File videoFile, {String folder = 'videos'}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(videoFile.path)}';
      final ref = _storage.ref().child('uploads/$userId/$folder/$fileName');

      final uploadTask = await ref.putFile(
        videoFile,
        SettableMetadata(contentType: _getMimeType(videoFile.path, 'video/mp4')),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Firebase Storage video upload success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Firebase Storage video upload error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ PDF / DOCUMENT UPLOAD
  // ============================================================
  static Future<String?> uploadPdf(File pdfFile, {String folder = 'documents'}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pdfFile.path)}';
      final ref = _storage.ref().child('uploads/$userId/$folder/$fileName');

      final uploadTask = await ref.putFile(
        pdfFile,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Firebase Storage PDF upload success: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Firebase Storage PDF upload error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ MULTIPLE IMAGES UPLOAD
  // ============================================================
  static Future<List<String>> uploadMultipleImages(List<File> images, {String folder = 'images'}) async {
    final List<String> uploadedUrls = [];

    for (var image in images) {
      final url = await uploadImage(image, folder: folder);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // ============================================================
  // ✅ UPLOAD MEDIA WITH TYPE DETECTION (Image, Video, Audio, PDF)
  // ============================================================
  static Future<String?> uploadMedia(File file, {String folder = 'media'}) async {
    try {
      final extension = file.path.split('.').last.toLowerCase();

      final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
      final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', '3gp'];
      final audioExtensions = ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac', 'amr'];

      if (imageExtensions.contains(extension)) {
        return await uploadImage(file, folder: 'images');
      } else if (videoExtensions.contains(extension)) {
        return await uploadVideo(file, folder: 'videos');
      } else if (audioExtensions.contains(extension)) {
        return await uploadAudio(file, folder: 'audios');
      } else if (extension == 'pdf') {
        return await uploadPdf(file, folder: 'documents');
      } else {
        // Fallback upload for raw files
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
        final ref = _storage.ref().child('uploads/$userId/$folder/$fileName');
        final uploadTask = await ref.putFile(file);
        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      print('❌ Media upload error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ UPLOAD MULTIPLE MEDIA FILES
  // ============================================================
  static Future<List<String>> uploadMultipleMedia(List<File> files, {String folder = 'media'}) async {
    final List<String> uploadedUrls = [];

    for (var file in files) {
      final url = await uploadMedia(file, folder: folder);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // ============================================================
  // ✅ PICK IMAGE FROM GALLERY
  // ============================================================
  static Future<File?> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('❌ Gallery pick error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ PICK IMAGE FROM CAMERA
  // ============================================================
  static Future<File?> pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('❌ Camera error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ PICK AUDIO
  // ============================================================
  static Future<File?> pickAudio() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickMedia();

      if (pickedFile != null) {
        final extension = pickedFile.path.split('.').last.toLowerCase();
        final audioExtensions = ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac', 'amr'];

        if (audioExtensions.contains(extension)) {
          return File(pickedFile.path);
        }
        return null;
      }
      return null;
    } catch (e) {
      print('❌ Audio pick error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ PICK VIDEO
  // ============================================================
  static Future<File?> pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('❌ Video pick error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ RECORD VIDEO FROM CAMERA
  // ============================================================
  static Future<File?> recordVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('❌ Video record error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ RECORD AUDIO
  // ============================================================
  static Future<File?> recordAudio() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickMedia();

      if (pickedFile != null) {
        final extension = pickedFile.path.split('.').last.toLowerCase();
        final audioExtensions = ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac', 'amr'];

        if (audioExtensions.contains(extension)) {
          return File(pickedFile.path);
        }
        return null;
      }
      return null;
    } catch (e) {
      print('❌ Audio record error: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ PICK MULTIPLE IMAGES
  // ============================================================
  static Future<List<File>> pickMultipleImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      print('❌ Multiple pick error: $e');
      return [];
    }
  }

  // ============================================================
  // ✅ GET MEDIA TYPE FROM URL OR FILE PATH
  // ============================================================
  static String getMediaType(String url) {
    final extension = url.split('.').last.split('?').first.toLowerCase();

    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
    final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', '3gp'];
    final audioExtensions = ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac', 'amr'];

    if (imageExtensions.contains(extension)) return 'image';
    if (videoExtensions.contains(extension)) return 'video';
    if (audioExtensions.contains(extension)) return 'audio';
    if (extension == 'pdf') return 'pdf';
    return 'unknown';
  }

  // ============================================================
  // ✅ DELETE FILE FROM FIREBASE STORAGE BY URL
  // ============================================================
  static Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      print('✅ Deleted file from Firebase Storage: $fileUrl');
      return true;
    } catch (e) {
      print('❌ Delete file error: $e');
      return false;
    }
  }

  // ============================================================
  // ℹ️ HELPER FOR MIME TYPE
  // ============================================================
  static String _getMimeType(String filePath, String fallback) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/m4a';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'pdf':
        return 'application/pdf';
      default:
        return fallback;
    }
  }
}

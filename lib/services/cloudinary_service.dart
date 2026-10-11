// lib/services/cloudinary_service.dart
// ⚠️ CLOUDINARY HAS BEEN MIGRATED TO FIREBASE STORAGE.
// All methods now redirect directly to FirebaseStorageService.

import 'dart:io';
import 'firebase_storage_service.dart';

class CloudinaryService {
  static Future<String?> uploadImage(File image) =>
      FirebaseStorageService.uploadImage(image);

  static Future<String?> uploadAudio(File audioFile) =>
      FirebaseStorageService.uploadAudio(audioFile);

  static Future<String?> uploadVideo(File videoFile) =>
      FirebaseStorageService.uploadVideo(videoFile);

  static Future<String?> uploadPdf(File pdfFile) =>
      FirebaseStorageService.uploadPdf(pdfFile);

  static Future<List<String>> uploadMultipleImages(List<File> images) =>
      FirebaseStorageService.uploadMultipleImages(images);

  static Future<File?> pickImageFromGallery() =>
      FirebaseStorageService.pickImageFromGallery();

  static Future<File?> pickImageFromCamera() =>
      FirebaseStorageService.pickImageFromCamera();

  static Future<File?> pickAudio() =>
      FirebaseStorageService.pickAudio();

  static Future<File?> pickVideo() =>
      FirebaseStorageService.pickVideo();

  static Future<File?> recordVideo() =>
      FirebaseStorageService.recordVideo();

  static Future<File?> recordAudio() =>
      FirebaseStorageService.recordAudio();

  static Future<List<File>> pickMultipleImages() =>
      FirebaseStorageService.pickMultipleImages();

  static Future<String?> uploadMedia(File file) =>
      FirebaseStorageService.uploadMedia(file);

  static Future<List<String>> uploadMultipleMedia(List<File> files) =>
      FirebaseStorageService.uploadMultipleMedia(files);

  static String getMediaType(String url) =>
      FirebaseStorageService.getMediaType(url);

  static Future<bool> deleteImage(String publicIdOrUrl) =>
      FirebaseStorageService.deleteFile(publicIdOrUrl);
}

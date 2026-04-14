import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<String>> uploadEventImages(
    String eventId,
    List<XFile> files,
  ) async {
    final urls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final ref = _storage.ref('events/$eventId/img_${i}_$timestamp.$ext');

      final metadata = SettableMetadata(
        contentType: file.mimeType ?? 'image/$ext',
      );

      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> deleteImages(List<String> urls) async {
    for (final url in urls) {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        debugPrint('Failed to delete image: $e');
      }
    }
  }

  Future<void> deleteAllEventImages(String eventId) async {
    try {
      final listResult = await _storage.ref('events/$eventId').listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete event images: $e');
    }
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageCompressionService {
  /// Resizes image to max [maxSize] px and compresses JPEG to under [targetBytes] (default 100KB)
  static Future<String?> compressAndConvertToBase64(
    Uint8List rawBytes, {
    int maxSize = 800,
    int targetBytes = 100 * 1024, // 100 KB
  }) async {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return null;

      // Calculate resized dimensions
      int width = decoded.width;
      int height = decoded.height;

      if (width > height) {
        if (width > maxSize) {
          height = (height * maxSize / width).round();
          width = maxSize;
        }
      } else {
        if (height > maxSize) {
          width = (width * maxSize / height).round();
          height = maxSize;
        }
      }

      final resized = img.copyResize(decoded, width: width, height: height);

      // Start with quality 85 and reduce if size > 100KB
      int quality = 85;
      List<int> jpegBytes = img.encodeJpg(resized, quality: quality);

      while (jpegBytes.length > targetBytes && quality > 15) {
        quality -= 10;
        jpegBytes = img.encodeJpg(resized, quality: quality);
      }

      final base64String = base64Encode(jpegBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      return null;
    }
  }

  /// Extracts raw Uint8List from Data URL or Base64 string for displaying Image.memory
  static Uint8List? decodeBase64(String? base64Data) {
    if (base64Data == null || base64Data.isEmpty) return null;
    try {
      String cleanStr = base64Data;
      if (cleanStr.contains(',')) {
        cleanStr = cleanStr.split(',').last;
      }
      return base64Decode(cleanStr);
    } catch (_) {
      return null;
    }
  }
}

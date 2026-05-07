import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ThumbnailService {
  ThumbnailService();
  static const _uuid = Uuid();

  /// Compresses [bytes] (jpg/png) to a JPEG thumbnail capped at 1200px on the
  /// long edge and saved to the app's documents directory under receipts/.
  /// Returns the absolute path on disk, or null on failure.
  Future<String?> saveCompressed(
    Uint8List bytes, {
    int maxLongEdge = 1200,
    int quality = 78,
  }) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final resized = (decoded.width > maxLongEdge ||
              decoded.height > maxLongEdge)
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxLongEdge : null,
              height: decoded.height > decoded.width ? maxLongEdge : null,
            )
          : decoded;
      final jpeg = img.encodeJpg(resized, quality: quality);
      final dir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${dir.path}/receipts');
      if (!receiptsDir.existsSync()) {
        receiptsDir.createSync(recursive: true);
      }
      final path = '${receiptsDir.path}/${_uuid.v4()}.jpg';
      await File(path).writeAsBytes(jpeg, flush: true);
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (f.existsSync()) await f.delete();
  }
}

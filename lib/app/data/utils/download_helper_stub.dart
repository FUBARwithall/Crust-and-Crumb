import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

void downloadBmpFile(Uint8List bmpBytes, String fileName) {
  try {
    Directory saveDir = Directory.systemTemp;
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      final picturesDir = Directory('/storage/emulated/0/Pictures');
      if (downloadDir.existsSync()) {
        saveDir = downloadDir;
      } else if (picturesDir.existsSync()) {
        saveDir = picturesDir;
      }
    }

    final file = File('${saveDir.path}/$fileName');
    file.writeAsBytesSync(bmpBytes);
    debugPrint('[DownloadHelper] BMP saved to public path: ${file.path}');
  } catch (e) {
    debugPrint('[DownloadHelper] Error saving BMP: $e');
  }
}

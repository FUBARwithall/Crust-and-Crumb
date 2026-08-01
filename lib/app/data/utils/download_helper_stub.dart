import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.example.junior_mobile_programmer/media_scanner');

Future<void> downloadBmpFile(Uint8List bmpBytes, String fileName) async {
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

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('scanFile', {'path': file.path});
        debugPrint('[DownloadHelper] MediaScanner notified for ${file.path}');
      } catch (e) {
        debugPrint('[DownloadHelper] MediaScanner error: $e');
      }
    }
  } catch (e) {
    debugPrint('[DownloadHelper] Error saving BMP: $e');
  }
}

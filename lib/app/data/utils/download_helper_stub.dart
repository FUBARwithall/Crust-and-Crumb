import 'dart:typed_data';

/// Stub implementation for non-web platforms.
/// Does nothing — BMP download is only supported on web.
void downloadBmpFile(Uint8List bmpBytes, String fileName) {
  // No-op on non-web platforms (Android/iOS/Desktop).
  // In future, you could use path_provider + file save dialog here.
}

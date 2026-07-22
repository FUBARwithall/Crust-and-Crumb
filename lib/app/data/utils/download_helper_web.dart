// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation — uses dart:html Blob + AnchorElement for BMP file download.
void downloadBmpFile(Uint8List bmpBytes, String fileName) {
  final blob = html.Blob([bmpBytes], 'image/bmp');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..download = fileName;
  anchor.click();
  html.Url.revokeObjectUrl(url);
}

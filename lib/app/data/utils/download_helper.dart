// Conditional export: uses web implementation on web, stub on all other platforms.
// This avoids importing dart:html on Android/iOS/Desktop which would cause compilation errors.
export 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

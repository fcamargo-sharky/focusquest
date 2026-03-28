// Selects the web implementation on web, no-op stub on all other platforms.
export 'sound_service_stub.dart'
    if (dart.library.js_interop) 'sound_service_web.dart';

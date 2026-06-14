export 'local_image_storage_stub.dart'
    if (dart.library.io) 'local_image_storage_io.dart'
    if (dart.library.js_interop) 'local_image_storage_web.dart';

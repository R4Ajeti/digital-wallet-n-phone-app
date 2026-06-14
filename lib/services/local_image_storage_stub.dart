import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

Future<String> persistLocalImage({
  required XFile picked,
  required String uid,
  required String kind,
}) {
  throw UnsupportedError('Local image storage is unavailable.');
}

Future<Uint8List?> readLocalImage({
  required String uid,
  required String kind,
  required String firebaseReference,
}) {
  throw UnsupportedError('Local image storage is unavailable.');
}

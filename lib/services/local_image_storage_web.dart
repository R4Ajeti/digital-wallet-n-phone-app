import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> persistLocalImage({
  required XFile picked,
  required String uid,
  required String kind,
}) async {
  final bytes = await picked.readAsBytes();
  final preferences = await SharedPreferences.getInstance();
  final saved = await preferences.setString(
    _dataKey(uid, kind),
    base64Encode(bytes),
  );
  if (!saved) {
    throw StateError('Browser storage rejected the image.');
  }
  return 'local-image://$kind/$uid';
}

Future<Uint8List?> readLocalImage({
  required String uid,
  required String kind,
  required String firebaseReference,
}) async {
  final preferences = await SharedPreferences.getInstance();
  final encoded = preferences.getString(_dataKey(uid, kind));
  if (encoded == null || encoded.isEmpty) {
    return null;
  }

  try {
    return base64Decode(encoded);
  } on FormatException {
    await preferences.remove(_dataKey(uid, kind));
    return null;
  }
}

String _dataKey(String uid, String kind) => 'local_image_data_${kind}_$uid';

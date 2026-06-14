import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> persistLocalImage({
  required XFile picked,
  required String uid,
  required String kind,
}) async {
  final documents = await getApplicationDocumentsDirectory();
  final folder = Directory(path.join(documents.path, 'kuleta_digitale', uid));
  await folder.create(recursive: true);

  final extension = path.extension(picked.name).toLowerCase();
  final safeExtension = extension.isEmpty ? '.jpg' : extension;
  final fileName =
      '${kind}_${DateTime.now().millisecondsSinceEpoch}$safeExtension';
  final savedFile = await File(
    picked.path,
  ).copy(path.join(folder.path, fileName));

  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(_cacheKey(uid, kind), savedFile.path);
  return savedFile.path;
}

Future<Uint8List?> readLocalImage({
  required String uid,
  required String kind,
  required String firebaseReference,
}) async {
  if (firebaseReference.isNotEmpty) {
    final firebaseFile = File(firebaseReference);
    if (await firebaseFile.exists()) {
      return firebaseFile.readAsBytes();
    }
  }

  final preferences = await SharedPreferences.getInstance();
  final cachedPath = preferences.getString(_cacheKey(uid, kind)) ?? '';
  if (cachedPath.isEmpty) {
    return null;
  }

  final cachedFile = File(cachedPath);
  return await cachedFile.exists() ? cachedFile.readAsBytes() : null;
}

String _cacheKey(String uid, String kind) => 'local_image_${kind}_$uid';

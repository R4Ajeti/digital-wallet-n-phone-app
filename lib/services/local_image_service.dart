import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocalImageKind { profile, overlay }

class LocalImageService {
  LocalImageService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<String?> pickAndPersist({
    required String uid,
    required LocalImageKind kind,
  }) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) {
      return null;
    }

    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(path.join(documents.path, 'kuleta_digitale', uid));
    await folder.create(recursive: true);

    final extension = path.extension(picked.name).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final fileName =
        '${kind.name}_${DateTime.now().millisecondsSinceEpoch}$safeExtension';
    final savedFile = await File(
      picked.path,
    ).copy(path.join(folder.path, fileName));

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cacheKey(uid, kind), savedFile.path);
    return savedFile.path;
  }

  Future<String> resolveAvailablePath({
    required String uid,
    required LocalImageKind kind,
    required String firebasePath,
  }) async {
    if (firebasePath.isNotEmpty && await File(firebasePath).exists()) {
      return firebasePath;
    }

    final preferences = await SharedPreferences.getInstance();
    final cachedPath = preferences.getString(_cacheKey(uid, kind)) ?? '';
    if (cachedPath.isNotEmpty && await File(cachedPath).exists()) {
      return cachedPath;
    }
    return '';
  }

  String _cacheKey(String uid, LocalImageKind kind) {
    return 'local_image_${kind.name}_$uid';
  }
}

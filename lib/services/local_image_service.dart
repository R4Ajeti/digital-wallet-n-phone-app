import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'local_image_storage.dart';

enum LocalImageKind { profile, overlay }

class LocalImageSelection {
  const LocalImageSelection({required this.reference, required this.bytes});

  final String reference;
  final Uint8List bytes;
}

class LocalImageException implements Exception {
  const LocalImageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalImageService {
  LocalImageService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  static const _maximumImageBytes = 1500000;

  final ImagePicker _imagePicker;

  Future<LocalImageSelection?> pickAndPersist({
    required String uid,
    required LocalImageKind kind,
  }) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1000,
    );
    if (picked == null) {
      return null;
    }

    final length = await picked.length();
    if (length > _maximumImageBytes) {
      throw const LocalImageException(
        'Imazhi është shumë i madh. Zgjidh një imazh më të vogël se 1.5 MB.',
      );
    }

    try {
      final reference = await persistLocalImage(
        picked: picked,
        uid: uid,
        kind: kind.name,
      );
      final bytes = await picked.readAsBytes();
      return LocalImageSelection(reference: reference, bytes: bytes);
    } catch (_) {
      throw const LocalImageException(
        'Imazhi nuk mund të ruhej në këtë pajisje.',
      );
    }
  }

  Future<Uint8List?> resolveAvailableBytes({
    required String uid,
    required LocalImageKind kind,
    required String firebasePath,
  }) async {
    return readLocalImage(
      uid: uid,
      kind: kind.name,
      firebaseReference: firebasePath,
    );
  }
}

import 'package:flutter/material.dart';

import '../models/app_session_user.dart';
import '../models/app_user_data.dart';
import '../services/database_service.dart';
import '../services/local_image_service.dart';
import '../widgets/local_image_editor.dart';

class QrOverlayIconScreen extends StatelessWidget {
  QrOverlayIconScreen({required this.user, super.key});

  final AppSessionUser user;
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserData>(
      initialData: AppUserData.demo(
        uid: user.uid,
        email: user.email,
        username: user.displayName,
      ),
      stream: _databaseService.watchUser(user.uid),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            AppUserData.demo(
              uid: user.uid,
              email: user.email,
              username: user.displayName,
            );
        return LocalImageEditor(
          uid: user.uid,
          title: 'Ndrysho ikonën e QR Kodit',
          subtitle: 'Zgjidh një ikonë origjinale për QR kodin',
          kind: LocalImageKind.overlay,
          firebasePath: data.overlayImagePath,
          previewIcon: Icons.wallet_rounded,
          squarePreview: true,
          autoSaveOnPick: true,
          onSave: (path) =>
              _databaseService.saveOverlayImagePath(user.uid, path),
        );
      },
    );
  }
}

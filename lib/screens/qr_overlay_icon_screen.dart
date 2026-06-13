import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user_data.dart';
import '../services/database_service.dart';
import '../services/local_image_service.dart';
import '../widgets/local_image_editor.dart';

class QrOverlayIconScreen extends StatelessWidget {
  QrOverlayIconScreen({required this.user, super.key});

  final User user;
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserData>(
      stream: _databaseService.watchUser(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return LocalImageEditor(
          uid: user.uid,
          title: 'Ndrysho ikonën e QR Kodit',
          subtitle: 'Zgjidh një ikonë origjinale për QR kodin',
          kind: LocalImageKind.overlay,
          firebasePath: snapshot.data!.overlayImagePath,
          previewIcon: Icons.wallet_rounded,
          squarePreview: true,
          onSave: (path) =>
              _databaseService.saveOverlayImagePath(user.uid, path),
        );
      },
    );
  }
}

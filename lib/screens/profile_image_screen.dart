import 'package:flutter/material.dart';

import '../models/app_session_user.dart';
import '../models/app_user_data.dart';
import '../services/database_service.dart';
import '../services/local_image_service.dart';
import '../widgets/local_image_editor.dart';

class ProfileImageScreen extends StatelessWidget {
  ProfileImageScreen({required this.user, super.key});

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
          title: 'Ndrysho fotografinë',
          subtitle: 'Zgjidh portretin për kartën demo',
          kind: LocalImageKind.profile,
          firebasePath: data.profileImagePath,
          previewIcon: Icons.person_rounded,
          onSave: (path) =>
              _databaseService.saveProfileImagePath(user.uid, path),
        );
      },
    );
  }
}

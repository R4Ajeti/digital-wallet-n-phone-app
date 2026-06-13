import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user_data.dart';
import '../services/database_service.dart';
import '../services/local_image_service.dart';
import '../widgets/local_image_editor.dart';

class ProfileImageScreen extends StatelessWidget {
  ProfileImageScreen({required this.user, super.key});

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
          title: 'Ndrysho fotografinë',
          subtitle: 'Zgjidh portretin për kartën demo',
          kind: LocalImageKind.profile,
          firebasePath: snapshot.data!.profileImagePath,
          previewIcon: Icons.person_rounded,
          onSave: (path) =>
              _databaseService.saveProfileImagePath(user.uid, path),
        );
      },
    );
  }
}

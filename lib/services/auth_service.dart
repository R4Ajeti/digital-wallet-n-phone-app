import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(username.trim());
    return credential;
  }

  Future<void> logout() => _auth.signOut();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nuk ka përdorues aktiv.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}

String authErrorInAlbanian(Object error) {
  if (error is FirebaseAuthException) {
    final message = error.message?.toUpperCase() ?? '';
    if (message.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Authentication nuk është aktivizuar ende. '
          'Hap Firebase Console, kliko Get started dhe aktivizo Email/Password.';
    }

    switch (error.code) {
      case 'invalid-email':
        return 'Email-i nuk është i vlefshëm.';
      case 'user-disabled':
        return 'Kjo llogari është çaktivizuar.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email-i ose fjalëkalimi është i pasaktë.';
      case 'email-already-in-use':
        return 'Ky email është përdorur nga një llogari tjetër.';
      case 'weak-password':
        return 'Zgjidh një fjalëkalim më të fortë.';
      case 'too-many-requests':
        return 'Ka pasur shumë tentativa. Provo përsëri më vonë.';
      case 'network-request-failed':
        return 'Kontrollo lidhjen me internetin.';
      case 'operation-not-allowed':
        return 'Kyçja me email nuk është aktivizuar. '
            'Aktivizo Email/Password në Firebase Authentication.';
      case 'requires-recent-login':
        return 'Kyçu përsëri para se ta ndryshosh fjalëkalimin.';
      case 'no-current-user':
        return 'Sesioni ka përfunduar. Kyçu përsëri.';
    }
  }
  return 'Diçka nuk shkoi mirë. Provo përsëri.';
}

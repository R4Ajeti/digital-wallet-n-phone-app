enum AppAuthProvider { password, google, anonymous }

class AppSessionUser {
  const AppSessionUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.provider = AppAuthProvider.password,
  });

  static const sharedGuestDataKey = 'shared_guest_default';
  static const sharedGuestProfileNamespace = 'shared_guest_profile';

  final String uid;
  final String email;
  final String displayName;
  final AppAuthProvider provider;

  bool get isAnonymous => provider == AppAuthProvider.anonymous;
  bool get canChangePassword => provider == AppAuthProvider.password;
  String get dataKey => isAnonymous ? sharedGuestDataKey : uid;
  String get profileImageNamespace =>
      isAnonymous ? sharedGuestProfileNamespace : uid;
}

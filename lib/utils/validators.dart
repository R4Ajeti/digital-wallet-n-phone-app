String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Shkruaj email-in.';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Shkruaj një email të vlefshëm.';
  }
  return null;
}

String? validateRequired(String? value, String message) {
  if ((value ?? '').trim().isEmpty) {
    return message;
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return 'Shkruaj fjalëkalimin.';
  }
  if (password.length < 6) {
    return 'Fjalëkalimi duhet të ketë së paku 6 karaktere.';
  }
  return null;
}

/// Form validation rules.
///
/// Each returns `null` when valid and a user-facing message otherwise, matching
/// the signature Flutter's `TextFormField.validator` expects. Kept pure so the
/// rules can be unit tested without pumping a widget.
abstract final class Validators {
  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static const int taskTitleMaxLength = 100;
  static const int descriptionMaxLength = 500;
  static const int projectNameMaxLength = 60;
  static const int minPasswordLength = 8;

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Enter your email address';
    if (!_emailPattern.hasMatch(input)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Enter your password';
    if (input.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    return null;
  }

  /// Login only checks that a password was typed; strength rules belong to
  /// registration so existing accounts are never locked out by a rule change.
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Re-enter your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Enter your name';
    if (input.length < 2) return 'Name is too short';
    if (input.length > 60) return 'Name must be 60 characters or fewer';
    return null;
  }

  static String? taskTitle(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Give the task a title';
    if (input.length < 3) return 'Title must be at least 3 characters';
    if (input.length > taskTitleMaxLength) {
      return 'Title must be $taskTitleMaxLength characters or fewer';
    }
    return null;
  }

  static String? projectName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Give the project a name';
    if (input.length < 3) return 'Name must be at least 3 characters';
    if (input.length > projectNameMaxLength) {
      return 'Name must be $projectNameMaxLength characters or fewer';
    }
    return null;
  }

  /// Descriptions are optional everywhere, so only the ceiling is enforced.
  static String? description(String? value) {
    final input = value?.trim() ?? '';
    if (input.length > descriptionMaxLength) {
      return 'Description must be $descriptionMaxLength characters or fewer';
    }
    return null;
  }
}

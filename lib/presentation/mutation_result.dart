/// Outcome of a mutation.
///
/// Expected, recoverable failures (validation, permission, offline) are
/// returned rather than thrown, so screens can show a message inline instead
/// of wrapping every call in try/catch.
sealed class MutationResult<T> {
  const MutationResult();

  bool get isSuccess => this is MutationSuccess<T>;

  /// The failure message, or null when the mutation succeeded.
  String? get errorOrNull =>
      this is MutationFailure<T> ? (this as MutationFailure<T>).message : null;
}

class MutationSuccess<T> extends MutationResult<T> {
  const MutationSuccess(this.value);

  final T value;
}

class MutationFailure<T> extends MutationResult<T> {
  const MutationFailure(this.message, [this.fieldErrors = const {}]);

  final String message;

  /// Field-level messages keyed by form field name, when the server rejected
  /// specific inputs.
  final Map<String, String> fieldErrors;
}

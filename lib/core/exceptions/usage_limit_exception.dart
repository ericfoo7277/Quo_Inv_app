/// Thrown when a free-tier user attempts to exceed their monthly usage limit.
class UsageLimitException implements Exception {
  const UsageLimitException(this.message);

  final String message;

  @override
  String toString() => message;
}

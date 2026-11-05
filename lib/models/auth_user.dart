/// Minimal authenticated user identity; never persist passwords or tokens.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.providers = const [],
  });
  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;
  final List<String> providers;
  bool get hasGoogle => providers.contains('google.com');
}

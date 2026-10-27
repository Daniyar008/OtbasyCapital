class CloudAccount {
  const CloudAccount({
    required this.id,
    required this.email,
    required this.name,
  });
  final String id, email, name;
}

/// Auth and remote data boundary. The Hive outbox can be tested without a server.
abstract interface class FinanceCloud {
  CloudAccount? get account;
  Future<void> signIn(String email, String password);

  /// False means email confirmation is required before a session is available.
  Future<bool> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<Map<String, dynamic>?> download(String userId);
  Future<void> upload(String userId, Map<String, dynamic> state);
}

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

/// Optional capability used only by cloud backends that support Supabase Realtime.
/// Keeping it separate lets local storage and unit-test fakes stay simple.
abstract interface class RealtimeFinanceCloud {
  Stream<List<Map<String, dynamic>>> watchEntries(String userId);
}

/// Optional login capability. Google itself is configured in Supabase Auth.
abstract interface class GoogleAuthCloud {
  Future<void> signInWithGoogle();
}

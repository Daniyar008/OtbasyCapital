/// The project URL and publishable key are public client configuration.
/// Access to records is controlled by Auth JWT + PostgreSQL RLS policies.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cjssoiwliiaeenyicdxu.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_fp88xD3sJukBHHOCGKLA7g_Z7iCmrVU',
  );
}

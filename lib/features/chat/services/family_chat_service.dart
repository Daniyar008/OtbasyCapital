import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_chat_message.dart';

/// Supabase Realtime opens a WebSocket subscription for this stream.
class FamilyChatService {
  FamilyChatService(this.client);
  final SupabaseClient client;

  static FamilyChatService get instance =>
      FamilyChatService(Supabase.instance.client);

  Stream<List<FamilyChatMessage>> watchMessages() {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return Stream.error(StateError('Аккаунтқа кіріңіз.'));
    return client
        .from('otbasy_family_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('family_id', 'family-main')
        .map((rows) {
          final messages =
              rows.map(FamilyChatMessage.fromRow).toList(growable: true)
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return List.unmodifiable(messages);
        });
  }

  Future<void> send({
    required String author,
    required String text,
    bool isAssistant = false,
  }) async {
    final userId = client.auth.currentUser?.id;
    final message = text.trim();
    if (userId == null) throw StateError('Аккаунтқа кіріңіз.');
    if (message.isEmpty) return;
    await client.from('otbasy_family_messages').insert({
      'user_id': userId,
      'family_id': 'family-main',
      'author_name': author,
      'message': message,
      'is_assistant': isAssistant,
    });
  }

  Future<void> clearMessages() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Аккаунтқа кіріңіз.');
    await client
        .from('otbasy_family_messages')
        .delete()
        .eq('user_id', userId)
        .eq('family_id', 'family-main');
  }
}

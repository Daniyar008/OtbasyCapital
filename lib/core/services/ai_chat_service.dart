import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_store.dart';
import '../../features/assistant/services/budget_assistant.dart';

/// Calls our Supabase Edge Function. The Gemini API key never enters Flutter.
class AiChatService {
  AiChatService(this.client);
  final SupabaseClient client;

  static AiChatService get instance => AiChatService(Supabase.instance.client);

  Future<String> ask(String message, AppStore store) async {
    final context = {
      'family': store.family,
      'period': '${store.period.year}-${store.period.month}',
      'income': store.income,
      'expense': store.expense,
      'balance': store.balance,
      'categories': {
        for (final category in AppStore.categories)
          category: store.categoryExpense(category),
      },
    };
    final result = await client.functions.invoke(
      'ai-chat',
      body: {'message': message, 'context': context},
    );
    final data = result.data;
    if (data is Map && data['answer'] is String) {
      return data['answer'] as String;
    }
    throw StateError('ЖИ сервисі дұрыс жауап қайтармады.');
  }

  /// Used only while the function is not available during local UI testing.
  String localFallback(String message, AppStore store) =>
      BudgetAssistant.reply(message, store);
}

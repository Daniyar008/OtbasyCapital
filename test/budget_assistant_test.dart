import 'package:flutter_test/flutter_test.dart';
import 'package:otbasy_capital/app/app_store.dart';
import 'package:otbasy_capital/core/services/storage_service.dart';
import 'package:otbasy_capital/features/assistant/services/budget_assistant.dart';

void main() {
  test('budget assistant gives answers from the current app data', () {
    final store = AppStore(storage: MemoryStorageService());

    expect(BudgetAssistant.reply('Қалдық қанша?', store), contains('Қазіргі'));
    expect(
      BudgetAssistant.reply('Шығыс қайда кетті?', store),
      contains('санат'),
    );
    expect(BudgetAssistant.reply('Үнемдеу кеңесі', store), contains('лимит'));

    store.dispose();
  });
}

import '../../../app/app_store.dart';
import '../../../core/utils/formatters.dart';

/// A transparent local assistant: it answers only from the user's budget data.
/// A paid external LLM can later be called from a secure server function.
class BudgetAssistant {
  const BudgetAssistant._();

  static String reply(String question, AppStore store) {
    final text = question.toLowerCase();
    final categories = [...AppStore.categories]
      ..sort(
        (a, b) => store.categoryExpense(b).compareTo(store.categoryExpense(a)),
      );
    final largest = categories.first;
    if (text.contains('қалдық') || text.contains('баланс')) {
      return 'Қазіргі қалдық: ${money(store.balance)}. '
          'Кіріс ${money(store.income)}, шығыс ${money(store.expense)}.';
    }
    if (text.contains('қайда') ||
        text.contains('шығыс') ||
        text.contains('жұмса')) {
      return store.expense == 0
          ? 'Осы айда шығыс әлі тіркелмеген.'
          : 'Ең көп шығын «$largest» санатында: '
                '${money(store.categoryExpense(largest))}.';
    }
    if (text.contains('кеңес') || text.contains('үнем')) {
      return store.expense == 0
          ? 'Алдымен күнделікті шығындарды енгізіп көріңіз.'
          : '«$largest» санатын қарап шығыңыз. Осы санатқа лимит қойып, '
                'әр сатып алуды чекпен бірге тіркеген ыңғайлы.';
    }
    return 'Мен бюджет деректері бойынша көмектесемін. '
        '«Қалдық қанша?», «Шығыс қайда кетті?» немесе «Үнемдеу кеңесі» деп сұраңыз.';
  }
}

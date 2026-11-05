import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final over = AppStore.categories
        .where((c) => store.categoryExpense(c) >= AppStore.limits[c]! * .8)
        .toList();
    return AppPage(
      title: 'Айлық бюджет',
      back: '/home',
      tab: 0,
      children: [
        Text(monthLabel(store.period), style: AppTheme.caption),
        BalanceCard(
          label: 'Жалпы лимит',
          amount: money(store.totalBudget),
          caption:
              'Жұмсалды ${money(store.expense)} · Қалды ${money(store.budgetLeft)}',
        ),
        _BudgetOverview(
          expense: store.expense,
          total: store.totalBudget,
          dailyLimit: store.plannedDailyLimit,
          suggestedDailyAmount: store.suggestedDailyAmount,
        ),
        if (over.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${over.join(', ')}: лимиттің 80%-ына жеттіңіз.',
              style: AppTheme.label.copyWith(color: AppColors.green),
            ),
          ),
        for (final category in AppStore.categories)
          AppCard(
            title: category,
            icon: category == 'Азық-түлік' ? 'food' : 'wallet',
            subtitle:
                '${money(store.categoryExpense(category))} / ${money(AppStore.limits[category]!)}',
          ),
        Text(
          '${store.sharedView ? 'Ортақ' : 'Жеке'} есеп. Лимиттер — оқу мысалы.',
          style: AppTheme.caption,
        ),
      ],
    );
  }
}

class _BudgetOverview extends StatelessWidget {
  const _BudgetOverview({
    required this.expense,
    required this.total,
    required this.dailyLimit,
    required this.suggestedDailyAmount,
  });

  final int expense;
  final int total;
  final int dailyLimit;
  final int suggestedDailyAmount;

  @override
  Widget build(BuildContext context) {
    final over = expense > total;
    final color = over ? AppColors.red : AppColors.green;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: over ? const Color(0xFFFFEFED) : AppColors.soft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                over ? Icons.warning_amber_rounded : Icons.insights_rounded,
                color: color,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  over
                      ? 'Бюджет лимитінен асып кеттіңіз'
                      : 'Бюджет жағдайы жақсы',
                  style: AppTheme.label.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (expense / total).clamp(0, 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: color,
            backgroundColor: Colors.white.withValues(alpha: .72),
          ),
          const SizedBox(height: 11),
          Text(
            over
                ? 'Шығындарды санаттар бойынша қарап, келесі төлемді кейінге қалдырыңыз.'
                : 'Жоспарлы орташа лимит: ${money(dailyLimit)} / күн. Қалған сома: ${money(suggestedDailyAmount)} / күн.',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return AppPage(
      title: 'Есептер',
      back: '/home',
      tab: 0,
      children: [
        Text(monthLabel(store.period), style: AppTheme.caption),
        BalanceCard(
          label: 'Айдың қорытындысы',
          amount: money(store.balance),
          caption:
              'Кіріс ${money(store.income)} · Шығыс ${money(store.expense)}',
        ),
        for (final category in AppStore.categories)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: AppTheme.label),
                Text(
                  '${money(store.categoryExpense(category))} • '
                  '${percent(store.categoryExpense(category), store.expense)}%',
                  style: AppTheme.label,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: store.expense == 0
                      ? 0
                      : store.categoryExpense(category) / store.expense,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: AppColors.soft,
                  color: AppColors.green,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

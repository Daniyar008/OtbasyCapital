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
          amount: '200 000 ₸',
          caption:
              'Жұмсалды ${money(store.expense)} · Қалды ${money(200000 - store.expense)}',
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

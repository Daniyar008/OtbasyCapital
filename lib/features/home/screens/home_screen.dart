import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../transactions/widgets/entry_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final entries = store.visibleEntries;
    final goal = store.goals.firstOrNull;
    return AppPage(
      title: 'Сәлем, ${store.name}!',
      tab: 0,
      trailing: Semantics(
        button: true,
        label: 'Профильді ашу',
        child: InkWell(
          onTap: () => context.go('/profile'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              store.name.isEmpty
                  ? 'О'
                  : store.name.characters.first.toUpperCase(),
              style: AppTheme.heading.copyWith(color: AppColors.green),
            ),
          ),
        ),
      ),
      children: [
        Text(
          '${store.family} • ${monthLabel(store.period)}',
          style: AppTheme.caption,
        ),
        Row(
          children: [
            Expanded(
              child: AppButton(
                'Ортақ',
                kind: store.sharedView
                    ? ButtonKind.secondary
                    : ButtonKind.quiet,
                onPressed: () => store.selectView(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                'Жеке',
                kind: !store.sharedView
                    ? ButtonKind.secondary
                    : ButtonKind.quiet,
                onPressed: () => store.selectView(false),
              ),
            ),
          ],
        ),
        BalanceCard(
          label: store.sharedView ? 'Жалпы қалдық' : 'Жеке қалдық',
          amount: money(store.balance),
          caption:
              'Кіріс ${money(store.income)} · Шығыс ${money(store.expense)}',
        ),
        Row(
          children: [
            Expanded(
              child: _MoneySummary(
                label: 'Кіріс',
                amount: money(store.income),
                income: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MoneySummary(
                label: 'Шығыс',
                amount: money(store.expense),
                income: false,
              ),
            ),
          ],
        ),
        AppButton(
          '+ Операция қосу',
          onPressed: () => context.push('/entry/new'),
        ),
        const Text('Соңғы операциялар', style: AppTheme.heading),
        if (entries.isEmpty)
          const EmptyState(
            'Әзірге операция жоқ',
            'Алғашқы кіріс немесе шығысты қосыңыз.',
            icon: 'wallet',
          )
        else
          ...entries.take(3).map((entry) => EntryCard(entry: entry)),
        AppButton(
          'Барлық операциялар',
          kind: ButtonKind.quiet,
          onPressed: () => context.go('/history'),
        ),
        AppCard(
          title: 'Айлық бюджет',
          icon: 'wallet',
          subtitle:
              '${money(store.expense)} / 200 000 ₸ · ${percent(store.expense, 200000)}%',
          trailing: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: (store.expense / 200000).clamp(0, 1),
              strokeWidth: 3,
              backgroundColor: AppColors.soft,
              color: store.expense > 200000 ? AppColors.red : AppColors.green,
              semanticsLabel: 'Бюджеттің жұмсалған үлесі',
            ),
          ),
          onTap: () => context.push('/budget'),
        ),
        if (goal != null)
          AppCard(
            title: goal.title,
            icon: 'target',
            soft: true,
            subtitle:
                '${money(goal.saved)} / ${money(goal.target)} · ${percent(goal.saved, goal.target)}%',
            onTap: () => context.push('/goal/${goal.id}'),
          ),
        AppCard(
          title: 'ЖИ көмекші',
          icon: 'spark',
          subtitle: 'Бюджетіңіз туралы сұраңыз',
          onTap: () => context.push('/assistant'),
        ),
        AppButton(
          'Есептерді көру',
          kind: ButtonKind.secondary,
          onPressed: () => context.push('/reports'),
        ),
        if (store.storageError != null)
          Text(
            store.storageError!,
            style: AppTheme.body.copyWith(color: AppColors.red),
          ),
      ],
    );
  }
}

class _MoneySummary extends StatelessWidget {
  const _MoneySummary({
    required this.label,
    required this.amount,
    required this.income,
  });
  final String label, amount;
  final bool income;
  @override
  Widget build(BuildContext context) {
    final color = income ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                income ? Icons.south_west_rounded : Icons.north_east_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: AppTheme.caption)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AppTheme.label.copyWith(fontSize: 17, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

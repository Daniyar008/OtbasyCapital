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
          EntryCard(entry: entries.first),
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

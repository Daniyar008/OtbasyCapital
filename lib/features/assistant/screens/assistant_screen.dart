import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final categories = [...AppStore.categories]
      ..sort(
        (a, b) => store.categoryExpense(b).compareTo(store.categoryExpense(a)),
      );
    return AppPage(
      title: 'ЖИ көмекші',
      back: '/home',
      children: [
        const AppCard(
          title: 'Отбасылық көмекші',
          subtitle: 'Енгізілген мәлімет бойынша жауап',
          icon: 'spark',
          soft: true,
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Осы айда ақша қайда жұмсалды?',
            style: AppTheme.body.copyWith(color: Colors.white),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${monthLabel(store.period)}: кіріс — ${money(store.income)}, '
            'шығыс — ${money(store.expense)}, қалдық — ${money(store.balance)}.\n\n'
            '${store.expense == 0 ? 'Осы айда шығыс тіркелмеген.' : 'Ең көп шығын «${categories.first}» санатында: ${money(store.categoryExpense(categories.first))}.'}',
          ),
        ),
        const Text(
          'Бұл жауап жергілікті есептеулерден құралады. ЖИ сервисі қосылмаған.',
          style: AppTheme.caption,
        ),
        AppButton(
          'Есепті ашу',
          kind: ButtonKind.secondary,
          onPressed: () => context.push('/reports'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/money_entry.dart';
import '../../../core/theme/app_theme.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.entry});
  final MoneyEntry entry;
  @override
  Widget build(BuildContext context) => AppCard(
    key: ValueKey('entry-${entry.id}'),
    title: entry.title,
    icon: entry.favorite ? 'star' : entry.icon,
    subtitle: '${entry.owner} · ${entry.category}',
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 100),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${entry.income ? '+' : '-'}${money(entry.amount)}',
          style: AppTheme.label.copyWith(
            color: entry.income ? AppColors.green : AppColors.red,
          ),
        ),
      ),
    ),
    onTap: () => context.push('/entry/${entry.id}'),
  );
}

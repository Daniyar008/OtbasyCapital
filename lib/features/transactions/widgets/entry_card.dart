import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/money_entry.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.entry});
  final MoneyEntry entry;
  @override
  Widget build(BuildContext context) => AppCard(
    key: ValueKey('entry-${entry.id}'),
    title: entry.title,
    icon: entry.favorite ? 'star' : entry.icon,
    subtitle:
        '${entry.owner} · ${entry.category}    ${entry.income ? '+' : '-'}${money(entry.amount)}',
    onTap: () => context.push('/entry/${entry.id}'),
  );
}

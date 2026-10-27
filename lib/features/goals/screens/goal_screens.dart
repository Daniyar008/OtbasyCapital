import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/result_screen.dart';
import '../models/savings_goal.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final goals = AppScope.of(context).goals;
    return AppPage(
      title: 'Жинақ мақсаттары',
      tab: 2,
      children: [
        if (goals.isEmpty)
          const EmptyState(
            'Мақсаттар жоқ',
            'Алғашқы жинақ мақсатын құрыңыз.',
            icon: 'target',
          ),
        for (final goal in goals)
          if (goal == goals.first)
            Material(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/goal/${goal.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppIcon('target', color: AppColors.accent),
                      const SizedBox(height: 20),
                      Text(
                        goal.title,
                        style: AppTheme.heading.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${money(goal.saved)} / ${money(goal.target)}',
                        style: AppTheme.label.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${percent(goal.saved, goal.target)}% жиналды · ${dateLabel(goal.date)}',
                        style: AppTheme.caption.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            AppCard(
              title: goal.title,
              icon: 'target',
              subtitle:
                  '${goal.shared ? 'Ортақ' : 'Жеке'} мақсат · ${money(goal.saved)} / ${money(goal.target)}',
              onTap: () => context.push('/goal/${goal.id}'),
            ),
        AppButton('+ Мақсат қосу', onPressed: () => context.push('/goal/new')),
      ],
    );
  }
}

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final goal = AppScope.of(context).goal(id);
    if (goal == null) {
      return const AppPage(
        title: 'Мақсат табылмады',
        back: '/goals',
        children: [],
      );
    }
    return AppPage(
      title: 'Мақсат туралы',
      back: '/goals',
      tab: 2,
      children: [
        Text(goal.title, style: AppTheme.title),
        BalanceCard(
          label: 'Жиналды',
          amount: money(goal.saved),
          caption:
              '${money(goal.target)} мақсат · ${percent(goal.saved, goal.target)}% · ${dateLabel(goal.date)}',
        ),
        ...goal.contributions.entries.map(
          (e) => AppCard(title: e.key, subtitle: money(e.value), icon: 'user'),
        ),
        const Text(
          'Үлес — кейінге қалдырылған соманың есебі. Ақша аударылмайды.',
          style: AppTheme.caption,
        ),
        AppButton(
          'Үлес қосу',
          onPressed: () => context.push('/goal/$id/contribute'),
        ),
      ],
    );
  }
}

class GoalFormScreen extends StatefulWidget {
  const GoalFormScreen({super.key});
  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(), _amount = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 180));
  bool _shared = true, _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Мақсат құру',
    back: '/goals',
    formKey: _form,
    children: [
      AppField(
        'Мақсат атауы',
        controller: _title,
        validator: Validators.required,
        inputKey: const ValueKey('goal-title'),
        hint: 'Мысалы, отбасылық демалыс',
      ),
      AppField(
        'Қажетті сома',
        controller: _amount,
        validator: Validators.amount,
        keyboardType: TextInputType.number,
        inputKey: const ValueKey('goal-amount'),
        formatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      DateField(
        label: 'Жоспарланған күн',
        value: _date,
        futureOnly: true,
        onChanged: (value) => setState(() => _date = value),
      ),
      AppSelect(
        'Көрінуі',
        value: _shared ? 'Ортақ' : 'Жеке',
        items: const ['Ортақ', 'Жеке'],
        onChanged: (value) => setState(() => _shared = value == 'Ортақ'),
      ),
      AppButton(
        'Мақсатты сақтау',
        busy: _busy,
        onPressed: () async {
          if (!_form.currentState!.validate() || _busy) return;
          setState(() => _busy = true);
          final store = AppScope.of(context), id = AppScope.of(context).newId();
          await store.addGoal(
            SavingsGoal(
              id: id,
              title: _title.text.trim(),
              target: int.parse(_amount.text),
              date: _date,
              shared: _shared,
              owner: store.name,
              contributions: {},
            ),
          );
          if (context.mounted) context.go('/goal/$id');
        },
      ),
    ],
  );
}

class ContributionScreen extends StatefulWidget {
  const ContributionScreen({super.key, required this.id});
  final String id;
  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context),
        goal = AppScope.of(context).goal(widget.id);
    if (goal == null) {
      return const AppPage(
        title: 'Мақсат табылмады',
        back: '/goals',
        children: [],
      );
    }
    return AppPage(
      title: 'Жинаққа үлес қосу',
      back: '/goal/${widget.id}',
      formKey: _form,
      children: [
        AppCard(
          title: goal.title,
          subtitle: 'Таңдалған мақсат',
          icon: 'target',
          soft: true,
        ),
        AppField(
          'Үлес сомасы',
          controller: _amount,
          validator: Validators.amount,
          inputKey: const ValueKey('contribution-amount'),
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        Text(dateLabel(DateTime.now()), style: AppTheme.caption),
        const Text(
          'Үлес жинақ есебіне қосылады. Қалдық сомасынан алынбайды.',
          style: AppTheme.caption,
        ),
        AppButton(
          'Үлесті сақтау',
          busy: _busy,
          onPressed: () async {
            if (!_form.currentState!.validate() || _busy) return;
            setState(() => _busy = true);
            await store.contribute(widget.id, int.parse(_amount.text));
            if (!context.mounted) return;
            final updated = store.goal(widget.id)!;
            context.go(
              '/result',
              extra: ResultData(
                title: 'Үлес сақталды',
                amount: money(updated.saved),
                message:
                    'Мақсаттың ${percent(updated.saved, updated.target)}%-ы орындалды.',
                destination: '/goal/${widget.id}',
                button: 'Мақсатқа оралу',
                secondaryDestination: '/profile',
                secondaryButton: 'Профильге өту',
              ),
            );
          },
        ),
      ],
    );
  }
}

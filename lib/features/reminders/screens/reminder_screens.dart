import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/result_screen.dart';
import '../models/payment_reminder.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return AppPage(
      title: 'Еске салғыштар',
      back: '/profile',
      tab: 3,
      children: [
        if (store.reminders.isEmpty)
          const EmptyState(
            'Еске салғыштар жоқ',
            'Алғашқы төлем жоспарын қосыңыз.',
            icon: 'bell',
          ),
        ...store.reminders.map(
          (r) => AppCard(
            title: r.title,
            subtitle:
                '${dateLabel(r.date)} · ${r.monthly ? 'Ай сайын' : 'Бір рет'}'
                '${r.done ? ' · Орындалды' : ''}',
            icon: 'bell',
            soft: r.done,
            trailing: IconButton(
              tooltip: r.done
                  ? 'Орындалмады деп белгілеу'
                  : 'Орындалды деп белгілеу',
              onPressed: () => store.toggleReminder(r.id),
              icon: Icon(
                r.done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: AppColors.green,
              ),
            ),
          ),
        ),
        AppButton(
          '+ Еске салғыш қосу',
          onPressed: () => context.push('/reminder/new'),
        ),
        AppButton(
          'Хабарландыру баптаулары',
          kind: ButtonKind.secondary,
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({super.key});
  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _form = GlobalKey<FormState>(), _title = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _monthly = true, _busy = false;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Еске салғыш қосу',
    back: '/reminders',
    formKey: _form,
    children: [
      AppField(
        'Төлем атауы',
        controller: _title,
        validator: Validators.required,
        inputKey: const ValueKey('reminder-title'),
        hint: 'Мысалы, интернет төлемі',
      ),
      DateField(
        value: _date,
        futureOnly: true,
        onChanged: (v) => setState(() => _date = v),
      ),
      AppSelect(
        'Қайталануы',
        value: _monthly ? 'Ай сайын' : 'Бір рет',
        items: const ['Ай сайын', 'Бір рет'],
        onChanged: (v) => setState(() => _monthly = v == 'Ай сайын'),
      ),
      AppButton(
        'Сақтау',
        busy: _busy,
        onPressed: () async {
          if (!_form.currentState!.validate() || _busy) return;
          setState(() => _busy = true);
          final store = AppScope.of(context);
          await store.addReminder(
            PaymentReminder(
              id: store.newId(),
              title: _title.text.trim(),
              date: _date,
              monthly: _monthly,
            ),
          );
          if (context.mounted) {
            context.go(
              '/result',
              extra: ResultData(
                title: 'Еске салғыш сақталды',
                message: '${_title.text.trim()} · ${dateLabel(_date)}',
                destination: '/reminders',
                button: 'Еске салғыштарға оралу',
              ),
            );
          }
        },
      ),
    ],
  );
}

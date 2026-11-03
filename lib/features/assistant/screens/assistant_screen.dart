import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../services/budget_assistant.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _messages = <_AssistantMessage>[];

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _AssistantMessage(
        text: 'Сәлем! Қалдық, шығыс немесе үнемдеу туралы сұраңыз.',
        fromAssistant: true,
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _ask([String? readyQuestion]) {
    final text = (readyQuestion ?? _input.text).trim();
    if (text.isEmpty) return;
    final store = AppScope.of(context);
    setState(() {
      _messages
        ..add(_AssistantMessage(text: text, fromAssistant: false))
        ..add(
          _AssistantMessage(
            text: BudgetAssistant.reply(text, store),
            fromAssistant: true,
          ),
        );
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'ЖИ көмекші',
    back: '/home',
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Бұл көмекші осы қосымшадағы кіріс, шығыс және санат деректері '
          'негізінде жауап береді.',
          style: AppTheme.caption,
        ),
      ),
      for (final item in _messages)
        Align(
          alignment: item.fromAssistant
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 310),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.fromAssistant ? Colors.white : AppColors.green,
              borderRadius: BorderRadius.circular(18),
              border: item.fromAssistant
                  ? Border.all(color: AppColors.line)
                  : null,
            ),
            child: Text(
              item.text,
              style: AppTheme.body.copyWith(
                color: item.fromAssistant ? AppColors.ink : Colors.white,
              ),
            ),
          ),
        ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            label: const Text('Қалдық қанша?'),
            onPressed: () => _ask('Қалдық қанша?'),
          ),
          ActionChip(
            label: const Text('Шығыс қайда кетті?'),
            onPressed: () => _ask('Шығыс қайда кетті?'),
          ),
          ActionChip(
            label: const Text('Үнемдеу кеңесі'),
            onPressed: () => _ask('Үнемдеу кеңесі'),
          ),
        ],
      ),
      TextFormField(
        key: const ValueKey('assistant-input'),
        controller: _input,
        textInputAction: TextInputAction.send,
        onFieldSubmitted: (_) => _ask(),
        decoration: InputDecoration(
          hintText: 'Сұрағыңызды жазыңыз',
          suffixIcon: IconButton(
            tooltip: 'Жіберу',
            icon: const Icon(Icons.send_rounded),
            onPressed: _ask,
          ),
        ),
      ),
      AppButton(
        'Отбасылық чатқа өту',
        kind: ButtonKind.secondary,
        onPressed: () => context.push('/family-chat'),
      ),
    ],
  );
}

class _AssistantMessage {
  const _AssistantMessage({required this.text, required this.fromAssistant});
  final String text;
  final bool fromAssistant;
}

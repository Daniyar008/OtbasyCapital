import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/services/ai_chat_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _messages = <_AssistantMessage>[];
  bool _thinking = false;

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

  Future<void> _ask([String? readyQuestion]) async {
    final text = (readyQuestion ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    final store = AppScope.of(context);
    setState(() {
      _messages.add(_AssistantMessage(text: text, fromAssistant: false));
      _input.clear();
      _thinking = true;
    });
    var answer = '';
    try {
      answer = await AiChatService.instance.ask(text, store);
    } catch (_) {
      answer =
          '${AiChatService.instance.localFallback(text, store)}\n\n'
          'ЖИ сервисі қазір қолжетімсіз, сондықтан жергілікті есеп қолданылды.';
    }
    if (!mounted) return;
    setState(() {
      _messages.add(_AssistantMessage(text: answer, fromAssistant: true));
      _thinking = false;
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
          'Gemini AI бюджет деректерімен бірге жауап береді. Интернет болмаса, '
          'жергілікті қысқа жауап қолданылады.',
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
      if (_thinking)
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
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

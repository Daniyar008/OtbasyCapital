import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_chat_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/family_chat_message.dart';
import '../services/family_chat_service.dart';

class FamilyChatScreen extends StatefulWidget {
  const FamilyChatScreen({super.key});

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  final _service = FamilyChatService.instance;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    if (_sending || _message.text.trim().isEmpty) return;
    final store = AppScope.of(context);
    final text = _message.text.trim();
    setState(() => _sending = true);
    try {
      await _service.send(author: store.name, text: text);
      _message.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
      if (text.toLowerCase().contains('@көмекші')) {
        final answer = await AiChatService.instance.ask(text, store);
        await _service.send(
          author: 'Қаржы көмекшісі',
          text: answer,
          isAssistant: true,
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, 'Хабар жіберілмеді: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await confirmAction(
      context,
      title: 'Чатты тазалау',
      message: 'Барлық ескі хабарлар осы аккаунттан жойылады.',
      confirm: 'Тазалау',
    );
    if (!confirmed) return;
    try {
      await _service.clearMessages();
      if (mounted) showMessage(context, 'Чат тазаланды.');
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Чатты тазалау үшін Supabase SQL migration-ды бір рет орындаңыз.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return AppPage(
      title: 'Отбасылық чат',
      back: '/home',
      tab: 0,
      scrollController: _scroll,
      trailing: IconButton(
        tooltip: 'Чатты тазалау',
        onPressed: _sending ? null : _clearChat,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
      children: [
        StreamBuilder<List<FamilyChatMessage>>(
          stream: _service.watchMessages(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyState(
                'Чатқа қосылмады',
                'Интернетті тексеріңіз немесе Realtime migration-ды орындаңыз.',
                icon: 'history',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final messages = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _scrollToLatest();
            });
            if (messages.isEmpty) {
              return const EmptyState(
                'Әзірге хабар жоқ',
                'Отбасы тобына бірінші хабарлама жіберіңіз.',
                icon: 'user',
              );
            }
            return Column(
              children: [
                for (final item in messages)
                  _ChatBubble(
                    message: item,
                    mine: item.author == store.name && !item.isAssistant,
                  ),
              ],
            );
          },
        ),
        TextFormField(
          key: const ValueKey('family-chat-input'),
          controller: _message,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.send,
          onFieldSubmitted: (_) => _send(),
          decoration: InputDecoration(
            hintText: 'Хабарлама жазыңыз немесе @көмекші деп сұраңыз',
            suffixIcon: IconButton(
              tooltip: 'Жіберу',
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.mine});
  final FamilyChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final assistant = message.isAssistant;
    final color = mine
        ? AppColors.green
        : assistant
        ? const Color(0xFFEDF5FF)
        : Colors.white;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: mine ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.author,
              style: AppTheme.caption.copyWith(
                color: mine ? Colors.white70 : AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: AppTheme.body.copyWith(
                color: mine ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

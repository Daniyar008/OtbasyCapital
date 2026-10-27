import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/result_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return AppPage(
      title: 'Профиль',
      tab: 3,
      children: [
        AppCard(
          title: store.name,
          subtitle: store.email,
          icon: 'user',
          soft: true,
        ),
        AppCard(
          title: 'Менің отбасым',
          subtitle: store.family,
          icon: 'home',
          onTap: () => context.push('/family'),
        ),
        AppCard(
          title: 'Таңдаулылар',
          icon: 'star',
          onTap: () => context.push('/favorites'),
        ),
        AppCard(
          title: 'Еске салғыштар',
          icon: 'bell',
          onTap: () => context.push('/reminders'),
        ),
        AppCard(
          title: 'Баптаулар',
          icon: 'user',
          onTap: () => context.push('/settings'),
        ),
        AppButton(
          'Аккаунттан шығу',
          kind: ButtonKind.quiet,
          onPressed: () {
            store.signOut();
            context.go('/login');
          },
        ),
      ],
    );
  }
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final members = ['Жансая', 'Мирас', 'Данияр', 'Нұрсұлтан'];
    if (!members.contains(store.name)) members.add(store.name);
    return AppPage(
      title: 'Менің отбасым',
      back: '/profile',
      tab: 3,
      children: [
        AppCard(
          title: store.family,
          subtitle: '${members.length} қатысушы',
          icon: 'home',
          soft: true,
        ),
        for (final member in members)
          AppCard(
            title: member,
            subtitle: member == 'Жансая' ? 'Әкімші' : 'Мүше',
            icon: 'user',
          ),
        const Text(
          'Жеке жазбалар жалпы тізімге кірмейді. '
          'Бұл оқу нұсқасы бірнеше құрылғы арасында синхрондалмайды.',
          style: AppTheme.caption,
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _initialized = false,
      _large = false,
      _notifications = true,
      _busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final store = AppScope.of(context);
    _large = store.largeText;
    _notifications = store.notifications;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return AppPage(
      title: 'Баптаулар',
      back: '/profile',
      tab: 3,
      children: [
        const AppCard(title: 'Тіл', subtitle: 'Қазақша', icon: 'user'),
        _switch(
          'Мәтін өлшемі',
          _large ? 'Үлкен' : 'Қалыпты',
          _large,
          (value) => setState(() => _large = value),
          const ValueKey('large-text'),
        ),
        _switch(
          'Хабарландырулар',
          _notifications ? 'Қосулы' : 'Өшірулі',
          _notifications,
          (value) => setState(() => _notifications = value),
          const ValueKey('notifications'),
        ),
        const Text(
          'Хабарландыру таңдауы сақталады. Жүйелік push хабарландырулар '
          'бұл оқу нұсқасына қосылмаған.',
          style: AppTheme.caption,
        ),
        AppButton(
          'Өзгерістерді сақтау',
          busy: _busy,
          onPressed: () async {
            setState(() => _busy = true);
            await store.setSettings(
              largeText: _large,
              notifications: _notifications,
            );
            if (context.mounted) {
              context.go(
                '/result',
                extra: const ResultData(
                  title: 'Баптаулар сақталды',
                  message: 'Мәтін өлшемі мен хабарландыру таңдауы сақталды.',
                ),
              );
            }
          },
        ),
        AppButton(
          'Құпиясөзді өзгерту',
          kind: ButtonKind.secondary,
          onPressed: () => context.push('/reset-password'),
        ),
        AppButton(
          'Оқу деректерін қалпына келтіру',
          kind: ButtonKind.quiet,
          onPressed: () async {
            if (!await confirmAction(
              context,
              title: 'Оқу деректерін қалпына келтіру',
              message:
                  'Қосқан операциялар, мақсаттар және еске салғыштар '
                  'бастапқы мысалдармен ауыстырылады.',
              confirm: 'Қалпына келтіру',
            )) {
              return;
            }
            await store.resetDemo();
            if (context.mounted) {
              showMessage(context, 'Бастапқы мысалдар қалпына келтірілді.');
            }
          },
        ),
      ],
    );
  }

  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Key key,
  ) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: SwitchListTile(
      key: key,
      value: value,
      onChanged: onChanged,
      title: Text(title, style: AppTheme.label),
      subtitle: Text(subtitle, style: AppTheme.caption),
    ),
  );
}

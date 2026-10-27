import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../app/app_scope.dart';
import 'cloud_sync_banner.dart';

class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.color});
  final String name;
  final Color? color;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: 24,
    height: 24,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

enum ButtonKind { primary, secondary, quiet, danger }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.kind = ButtonKind.primary,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final background = switch (kind) {
      ButtonKind.primary => AppColors.green,
      ButtonKind.secondary => AppColors.soft,
      ButtonKind.quiet => Colors.transparent,
      ButtonKind.danger => AppColors.red,
    };
    final foreground = kind == ButtonKind.primary || kind == ButtonKind.danger
        ? Colors.white
        : AppColors.green;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
        ),
        child: busy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Күте тұрыңыз…'),
                ],
              )
            : Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class AppField extends StatelessWidget {
  const AppField(
    this.label, {
    super.key,
    required this.controller,
    this.validator,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.inputKey,
    this.formatters,
    this.suffix,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? hint;
  final bool obscure, readOnly;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Key? inputKey;
  final List<TextInputFormatter>? formatters;
  final Widget? suffix;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTheme.label),
      const SizedBox(height: 8),
      TextFormField(
        key: inputKey,
        controller: controller,
        validator: validator,
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: onChanged,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: formatters,
        maxLines: maxLines,
        style: AppTheme.body,
        autocorrect: !obscure && keyboardType != TextInputType.emailAddress,
        enableSuggestions: !obscure,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
      ),
    ],
  );
}

class AppSelect extends StatelessWidget {
  const AppSelect(
    this.label, {
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label, value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTheme.label),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: value,
        isExpanded: true,
        style: AppTheme.body,
        decoration: const InputDecoration(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ],
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.soft = false,
    this.trailing,
  });
  final String title;
  final String? subtitle, icon;
  final VoidCallback? onTap;
  final bool soft;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Material(
    color: soft ? AppColors.soft : AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: soft
                      ? Colors.white.withValues(alpha: .65)
                      : AppColors.soft.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AppIcon(icon!),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.label),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: AppTheme.caption),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (trailing == null && onTap != null) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.label,
    required this.amount,
    this.caption,
  });
  final String label, amount;
  final String? caption;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A7058), Color(0xFF104D3D)],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: AppColors.green.withValues(alpha: .13),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned(
            right: -65,
            top: -85,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 35,
                ),
              ),
            ),
          ),
          Positioned(
            right: -45,
            bottom: -100,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .06),
                  width: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTheme.body.copyWith(
                          color: Colors.white.withValues(alpha: .86),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 320),
                      child: Text(
                        amount,
                        key: ValueKey(amount),
                        style: AppTheme.amount,
                      ),
                    ),
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    caption!,
                    style: AppTheme.caption.copyWith(
                      color: Colors.white.withValues(alpha: .76),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.back,
    this.tab,
    this.formKey,
    this.trailing,
  });
  final String title;
  final List<Widget> children;
  final String? back;
  final int? tab;
  final GlobalKey<FormState>? formKey;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (back != null) ...[
              Semantics(
                label: 'Артқа',
                button: true,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(back!);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: AppIcon('back'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: back == null ? AppTheme.title : AppTheme.heading,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
        if (tab != null && AppScope.of(context).cloudEnabled) ...[
          const SizedBox(height: 18),
          const CloudSyncBanner(),
        ],
        for (final child in children) ...[const SizedBox(height: 18), child],
      ],
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const ValueKey('page-scroll'),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: TweenAnimationBuilder<double>(
            key: ValueKey('entrance-$title'),
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: formKey == null
                ? content
                : Form(key: formKey, child: content),
            builder: (_, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: tab == null ? null : AppNavigation(selected: tab!),
    );
  }
}

class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key, required this.selected});
  final int selected;
  static const labels = ['Басты', 'Тарих', 'Мақсаттар', 'Профиль'];
  static const icons = ['home', 'history', 'target', 'user'];
  static const routes = ['/home', '/history', '/goals', '/profile'];
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .035),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  selected: selected == i,
                  button: true,
                  label: labels[i],
                  child: InkWell(
                    key: ValueKey('nav-$i'),
                    onTap: () => context.go(routes[i]),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected == i ? AppColors.green : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            icons[i],
                            color: selected == i
                                ? Colors.white
                                : AppColors.muted,
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: AppTheme.caption.copyWith(
                                color: selected == i
                                    ? Colors.white
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.title, this.message, {super.key, this.icon = 'search'});
  final String title, message, icon;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppIcon(icon),
      const SizedBox(height: 16),
      Text(title, style: AppTheme.heading),
      const SizedBox(height: 12),
      Text(message, style: AppTheme.body.copyWith(color: AppColors.muted)),
    ],
  );
}

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    this.label = 'Күні',
    required this.value,
    required this.onChanged,
    this.futureOnly = false,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool futureOnly;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTheme.label),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final today = DateUtils.dateOnly(DateTime.now());
            final first = futureOnly ? today : DateTime(2020);
            final picked = await showDatePicker(
              context: context,
              initialDate: value.isBefore(first) ? first : value,
              firstDate: first,
              lastDate: DateTime(2100),
              helpText: 'Күнді таңдаңыз',
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(child: Text(dateLabel(value))),
                const AppIcon('history'),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Иә, жою',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Бас тарту'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirm),
          ),
        ],
      ),
    ) ??
    false;

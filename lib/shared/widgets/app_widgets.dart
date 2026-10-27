import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

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
      ButtonKind.quiet => Colors.white,
      ButtonKind.danger => AppColors.red,
    };
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor:
              kind == ButtonKind.primary || kind == ButtonKind.danger
              ? Colors.white
              : AppColors.green,
        ),
        child: Text(busy ? 'Сақталуда…' : label, textAlign: TextAlign.center),
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
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[AppIcon(icon!), const SizedBox(width: 12)],
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
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.green,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.body.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        Text(amount, style: AppTheme.amount),
        if (caption != null) ...[
          const SizedBox(height: 8),
          Text(caption!, style: AppTheme.caption.copyWith(color: Colors.white)),
        ],
      ],
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
  });
  final String title;
  final List<Widget> children;
  final String? back;
  final int? tab;
  final GlobalKey<FormState>? formKey;
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
          ],
        ),
        for (final child in children) ...[const SizedBox(height: 20), child],
      ],
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const ValueKey('page-scroll'),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: formKey == null ? content : Form(key: formKey, child: content),
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
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected == i ? AppColors.soft : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(icons[i]),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: AppTheme.caption.copyWith(
                                color: selected == i
                                    ? AppColors.green
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

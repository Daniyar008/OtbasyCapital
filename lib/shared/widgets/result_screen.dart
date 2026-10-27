import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../core/theme/app_theme.dart';
import 'app_widgets.dart';

class ResultData {
  const ResultData({
    required this.title,
    required this.message,
    this.amount,
    this.destination = '/profile',
    this.button = 'Профильге өту',
    this.secondaryDestination,
    this.secondaryButton = 'Басты бетке оралу',
  });
  final String title, message, destination, button, secondaryButton;
  final String? amount, secondaryDestination;
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.data});
  final ResultData data;
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return AppPage(
      title: store.storageError == null ? data.title : 'Сақтау аяқталмады',
      children: [
        if (store.storageError == null)
          const Align(alignment: Alignment.centerLeft, child: AppIcon('check')),
        if (data.amount != null)
          BalanceCard(
            label: 'Жаңарған нәтиже',
            amount: data.amount!,
            caption: data.message,
          )
        else
          Text(
            data.message,
            style: AppTheme.body.copyWith(color: AppColors.muted),
          ),
        if (store.storageError != null)
          Text(
            store.storageError!,
            style: AppTheme.body.copyWith(color: AppColors.red),
          ),
        AppButton(data.button, onPressed: () => context.go(data.destination)),
        if (data.secondaryDestination != null)
          AppButton(
            data.secondaryButton,
            kind: ButtonKind.secondary,
            onPressed: () => context.go(data.secondaryDestination!),
          ),
      ],
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_store.dart';

/// Provider shares the state, while InheritedNotifier preserves the existing
/// screen API and rebuilds the widgets that depend on the store.
class AppScope extends InheritedNotifier<AppStore> {
  AppScope({super.key, required AppStore store, required Widget child})
    : super(
        notifier: store,
        child: ChangeNotifierProvider<AppStore>.value(
          value: store,
          child: child,
        ),
      );

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

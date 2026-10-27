import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_theme.dart';
import 'app_store.dart';

/// The first server/cache read also has a visible loading and retry state.
class StartupApp extends StatefulWidget {
  const StartupApp({super.key, required this.initialize});
  final Future<AppStore> Function() initialize;
  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  late Future<AppStore> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.initialize();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppStore>(
    future: _future,
    builder: (_, snapshot) {
      final failed =
          snapshot.connectionState == ConnectionState.done && snapshot.hasError;
      if (snapshot.hasData) {
        final store = snapshot.data!;
        return OtbasyApp(
          store: store,
          initialLocation: store.signedIn ? '/home' : '/',
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (_, _) => Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Icon(
                          failed
                              ? Icons.cloud_off_rounded
                              : Icons.account_balance_wallet_outlined,
                          color: AppColors.green,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Отбасы капиталы', style: AppTheme.heading),
                      const SizedBox(height: 14),
                      Text(
                        failed
                            ? 'Қосымшаны ашу мүмкін болмады. Интернетті тексеріп, қайта байқап көріңіз.'
                            : 'Деректер жүктелуде…',
                        textAlign: TextAlign.center,
                        style: AppTheme.body,
                      ),
                      const SizedBox(height: 24),
                      if (failed)
                        FilledButton(
                          key: const ValueKey('startup-retry'),
                          onPressed: () {
                            final next = widget.initialize();
                            setState(() {
                              _future = next;
                            });
                          },
                          child: const Text('Қайта байқап көру'),
                        )
                      else
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            key: ValueKey('startup-loading'),
                            strokeWidth: 2.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'app/app_router.dart';
import 'app/app_scope.dart';
import 'app/app_store.dart';
import 'core/theme/app_theme.dart';

class OtbasyApp extends StatefulWidget {
  const OtbasyApp({super.key, required this.store, this.initialLocation = '/'});
  final AppStore store;
  final String initialLocation;
  @override
  State<OtbasyApp> createState() => _OtbasyAppState();
}

class _OtbasyAppState extends State<OtbasyApp> {
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    _router = createRouter(
      widget.store,
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    store: widget.store,
    child: AnimatedBuilder(
      animation: widget.store,
      builder: (_, _) => MaterialApp.router(
        title: 'Отбасы капиталы',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        locale: const Locale('kk'),
        supportedLocales: const [Locale('kk'), Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => LayoutBuilder(
          builder: (context, constraints) {
            final media = MediaQuery.of(context);
            final scaler = TextScaler.linear(
              media.textScaler.scale(1) * (widget.store.largeText ? 1.25 : 1),
            );
            final wide = constraints.maxWidth >= 600;
            final height = wide
                ? math.max(100.0, math.min(900.0, constraints.maxHeight - 48))
                : constraints.maxHeight;
            final width = wide ? 390.0 : constraints.maxWidth;
            final screen = MediaQuery(
              data: media.copyWith(
                size: Size(width, height),
                textScaler: scaler,
              ),
              child: ColoredBox(
                color: AppColors.background,
                child: Padding(
                  padding: EdgeInsets.only(top: kIsWeb ? 32 : 0),
                  child: child!,
                ),
              ),
            );
            if (!wide) return screen;
            return ColoredBox(
              color: const Color(0xFFE7EDE7),
              child: Center(
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: .13),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: screen,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

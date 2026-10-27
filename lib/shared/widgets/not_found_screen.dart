import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../core/theme/app_theme.dart';
import 'app_widgets.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.location});
  final String? location;

  @override
  Widget build(BuildContext context) {
    final signedIn = AppScope.of(context).signedIn;
    return AppPage(
      title: 'Бет табылмады',
      children: [
        Container(
          height: 235,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: -30,
                top: -55,
                child: _circle(180, Colors.white.withValues(alpha: .6)),
              ),
              Positioned(
                left: -30,
                bottom: -80,
                child: _circle(200, AppColors.accent.withValues(alpha: .6)),
              ),
              Positioned(
                left: 28,
                top: 35,
                child: Transform.rotate(
                  angle: -.22,
                  child: const Icon(
                    Icons.explore_outlined,
                    size: 42,
                    color: AppColors.green,
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: 32,
                child: Transform.rotate(
                  angle: .18,
                  child: const Icon(
                    Icons.home_outlined,
                    size: 32,
                    color: AppColors.green,
                  ),
                ),
              ),
              const Text(
                '404',
                key: ValueKey('not-found-code'),
                style: TextStyle(
                  fontFamily: 'Noto Sans',
                  fontSize: 100,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -8,
                  color: AppColors.green,
                ),
              ),
              Positioned(
                right: 45,
                top: 35,
                child: _circle(10, AppColors.green.withValues(alpha: .25)),
              ),
            ],
          ),
        ),
        const Text(
          'Басқа жолмен жалғастырайық',
          textAlign: TextAlign.center,
          style: AppTheme.heading,
        ),
        const Text(
          'Бұл бет көшірілген немесе сілтеме қате болуы мүмкін. '
          'Қаржыңызға оралу үшін төмендегі түймені басыңыз.',
          textAlign: TextAlign.center,
          style: AppTheme.body,
        ),
        if (location != null)
          Text(
            location!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
        AppButton(
          'Басты бетке өту',
          onPressed: () => context.go(signedIn ? '/home' : '/'),
        ),
        AppButton(
          signedIn ? 'Операциялар тарихы' : 'Кіруге өту',
          kind: ButtonKind.secondary,
          onPressed: () => context.go(signedIn ? '/history' : '/login'),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

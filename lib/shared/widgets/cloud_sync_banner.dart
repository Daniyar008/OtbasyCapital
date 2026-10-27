import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/services/sync_state.dart';
import '../../core/theme/app_theme.dart';

class CloudSyncBanner extends StatelessWidget {
  const CloudSyncBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final cloud = store.cloud;
    if (cloud == null) return const SizedBox.shrink();
    final failed = cloud.phase == SyncPhase.error;
    final busy = store.syncing;
    final color = failed ? AppColors.red : AppColors.green;
    final title = busy
        ? 'Деректер жаңартылып жатыр'
        : failed
        ? 'Бұлт әлі жаңартылмады'
        : cloud.phase == SyncPhase.success
        ? 'Бұлтта сақталды'
        : 'Деректер дайын';
    return AnimatedContainer(
      key: const ValueKey('cloud-sync-banner'),
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
      decoration: BoxDecoration(
        color: failed
            ? AppColors.red.withValues(alpha: .06)
            : Colors.white.withValues(alpha: .8),
        border: Border.all(color: color.withValues(alpha: .12)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                busy
                    ? Icons.sync_rounded
                    : failed
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_outlined,
                color: color,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (failed && store.cloudError != null)
                      Text(
                        store.cloudError!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.caption.copyWith(fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (!busy)
                IconButton(
                  tooltip: 'Қайта синхрондау',
                  visualDensity: VisualDensity.compact,
                  onPressed: store.syncCloud,
                  icon: Icon(Icons.refresh_rounded, size: 20, color: color),
                ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: const LinearProgressIndicator(minHeight: 2),
            ),
          ],
        ],
      ),
    );
  }
}

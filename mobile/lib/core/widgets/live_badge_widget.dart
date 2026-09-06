import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../api/realtime_sync_service.dart';

class LiveBadgeWidget extends ConsumerWidget {
  const LiveBadgeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realtime = ref.watch(realtimeSyncProvider);
    final sync = ref.watch(syncProvider);

    final bool isOffline = sync.isOffline;
    final bool isSyncing = sync.isSyncing;
    final int pending = sync.pendingCount;
    final bool isLive = !isOffline && (realtime.isLive || pending == 0);

    final Color badgeColor = isOffline
        ? Colors.grey
        : (isSyncing || pending > 0
            ? Colors.amber.shade800
            : Colors.green);

    final String badgeLabel = isOffline
        ? 'Offline'
        : (isSyncing
            ? 'Syncing'
            : (pending > 0
                ? '$pending Pending'
                : (isLive ? 'Live' : 'Ready')));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withAlpha(60),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withAlpha(150),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            badgeLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

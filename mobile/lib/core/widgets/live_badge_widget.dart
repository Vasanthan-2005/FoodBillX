import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/realtime_sync_service.dart';

class LiveBadgeWidget extends ConsumerWidget {
  const LiveBadgeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(realtimeSyncProvider);
    final isLive = syncState.isLive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isLive ? Colors.green : Colors.amber).withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isLive ? Colors.green : Colors.amber).withAlpha(60),
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
              color: isLive ? Colors.green : Colors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isLive ? Colors.green : Colors.amber).withAlpha(150),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isLive ? 'Live' : 'Syncing',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isLive ? Colors.green.shade700 : Colors.amber.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

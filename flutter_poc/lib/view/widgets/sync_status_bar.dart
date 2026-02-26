import 'package:flutter/material.dart';
import 'package:flutter_poc/powersync/database.dart';
import 'package:powersync/powersync.dart';

class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: db.statusStream,
      builder: (context, statusSnap) {
        final status = statusSnap.data;
        final isConnected = status?.connected ?? false;

        final lastSynced = status?.lastSyncedAt;
        return Container(
          color: isConnected ? Colors.green[700] : Colors.red[700],
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isConnected
                      ? 'Online |  ${lastSynced != null ? 'Last sync: ${_fmt(lastSynced)}' : 'Never synced'}'
                      : 'Offline',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.white,
                icon: Icon(isConnected ? Icons.pause : Icons.play_arrow),
                onPressed: () async {
                  if (isConnected) {
                    await db.disconnect();
                  } else {
                    await db.connect(connector: connector);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

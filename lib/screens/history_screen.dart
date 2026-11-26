import 'package:flutter/material.dart';
import '../state/scanner_controller.dart';

class HistoryScreen extends StatelessWidget {
  final ScannerController controller;
  final VoidCallback onOpenResults;

  const HistoryScreen({
    super.key,
    required this.controller,
    required this.onOpenResults,
  });

  @override
  Widget build(BuildContext context) {
    final isFa = controller.isFa;
    final items = controller.history;

    if (items.isEmpty) {
      return Center(
        child: Text(
          isFa ? 'هنوز اسکنی ذخیره نشده است.' : 'No scan sessions recorded yet.',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFa ? 'تاریخچه اسکن‌ها (${items.length})' : 'Scan History (${items.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: controller.clearHistory,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.redAccent),
                label: Text(
                  isFa ? 'پاک‌سازی' : 'Clear',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, idx) {
              final s = items[idx];
              final dt = s.createdAt.toLocal();
              final dateStr =
                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.history_rounded, color: Color(0xFF00E676)),
                  title: Text(
                    '${s.passedCount}/${s.totalScanned} ${isFa ? "سالم" : "Passed"} • ${s.bestPingMs > 0 ? "${s.bestPingMs}ms" : "--"}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  subtitle: Text(
                    '$dateStr • ${s.countries.join(", ")}\n${s.engineName} • Best: ${s.bestIp}',
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    controller.loadSessionIntoResults(s);
                    onOpenResults();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

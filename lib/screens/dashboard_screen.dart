import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/proxy_database.dart';
import '../state/scanner_controller.dart';

class DashboardScreen extends StatelessWidget {
  final ScannerController controller;
  final VoidCallback onOpenResults;

  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onOpenResults,
  });

  @override
  Widget build(BuildContext context) {
    final isFa = controller.isFa;
    final p = controller.progress;
    final activeTargets = controller.buildActiveTargets();
    final topPassed = controller.allResults.where((r) => r.passed).take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status & Engine Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      controller.engineInfo.goAvailable
                          ? Icons.memory_rounded
                          : Icons.flash_on_rounded,
                      color: const Color(0xFF00E676),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isFa
                            ? 'موتور فعال: ${controller.activeEngineLabel}'
                            : 'Active Engine: ${controller.activeEngineLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${activeTargets.length} ${isFa ? "هدف" : "IPs"}',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Placement Region Selector
                DropdownButtonFormField<String>(
                  value: ProxyDatabase.placementPresets.contains(controller.config.placementRegion)
                      ? controller.config.placementRegion
                      : ProxyDatabase.placementPresets.first,
                  decoration: InputDecoration(
                    labelText: isFa ? 'ریجن Placement کلودفلر' : 'Cloudflare Placement Region',
                    prefixIcon: const Icon(Icons.cloud_outlined, size: 18),
                    isDense: true,
                  ),
                  items: ProxyDatabase.placementPresets
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: controller.isScanning
                      ? null
                      : (v) {
                          if (v != null) {
                            controller.updateConfig(
                              controller.config.copyWith(placementRegion: v),
                            );
                          }
                        },
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: controller.isScanning || p.total > 0 ? p.fraction : 0,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${p.completed} / ${p.total} (${(p.fraction * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      '${(p.elapsedMs / 1000).toStringAsFixed(1)}s • ${p.phase.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: controller.isScanning ? null : controller.startScan,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          isFa ? 'شروع اسکن' : 'Start Scan',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (controller.isScanning) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: controller.togglePause,
                        icon: Icon(
                          p.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: controller.stopScan,
                        icon: const Icon(Icons.stop_rounded, color: Colors.white),
                      ),
                    ],
                  ],
                ),
                if (controller.lastError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    controller.lastError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Live KPI Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            _kpiTile(
              isFa ? 'سالم (Passed)' : 'Passed',
              '${p.passed}',
              const Color(0xFF00E676),
              Icons.check_circle_outline,
            ),
            _kpiTile(
              isFa ? 'ناموفق (Failed)' : 'Failed',
              '${p.failed}',
              Colors.redAccent,
              Icons.cancel_outlined,
            ),
            _kpiTile(
              isFa ? 'بهترین پینگ' : 'Best Ping',
              p.bestPingMs > 0 ? '${p.bestPingMs} ms' : '--',
              Colors.cyanAccent,
              Icons.speed_rounded,
            ),
            _kpiTile(
              isFa ? 'میانگین سرعت' : 'Avg Speed',
              p.avgSpeedMbps > 0 ? '${p.avgSpeedMbps} Mbps' : '--',
              Colors.amberAccent,
              Icons.download_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Top 5 Live Leaderboard
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isFa ? '۵ پروکسی آی‌پی برتر' : 'Top 5 Fastest ProxyIPs',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: onOpenResults,
              child: Text(isFa ? 'مشاهده همه' : 'View All'),
            ),
          ],
        ),
        if (topPassed.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  isFa
                      ? 'برای دیدن بهترین آی‌پی‌ها، دکمه «شروع اسکن» را بزنید.'
                      : 'Tap Start Scan to benchmark selected country ProxyIPs.',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ),
          )
        else
          ...topPassed.map((r) {
            final meta = ProxyDatabase.metaFor(r.country);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(meta.flag, style: const TextStyle(fontSize: 22)),
                title: Text(
                  r.endpoint,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${r.provider} ${r.colo.isNotEmpty ? "• Colo: ${r.colo}" : ""} • Jitter: ${r.jitterMs}ms',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${r.avgLatencyMs} ms',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Score ${r.score}',
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: r.endpoint));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFa ? 'کپی شد: ${r.endpoint}' : 'Copied: ${r.endpoint}',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _kpiTile(String label, String value, Color accent, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

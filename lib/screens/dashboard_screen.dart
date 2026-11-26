import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/proxy_database.dart';
import '../models/scan_models.dart';
import '../state/scanner_controller.dart';
import '../widgets/mili_logo.dart';

const Color _kNeon = Color(0xFF00E676);
const Color _kSurface = Color(0xFF0E141C);
const Color _kSurfaceAlt = Color(0xFF121B25);

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
    final topPassed =
        controller.allResults.where((r) => r.passed).take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 26),
      children: [
        _heroBento(context, isFa, activeTargets.length),
        const SizedBox(height: 12),
        _progressBento(isFa, p),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiTile(
                isFa ? 'سالم' : 'Passed',
                '${p.passed}',
                _kNeon,
                Icons.verified_rounded,
                isFa ? 'در آخرین اسکن' : 'last run',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiTile(
                isFa ? 'ناموفق' : 'Failed',
                '${p.failed}',
                const Color(0xFFFF5C7A),
                Icons.cancel_rounded,
                isFa ? 'رد شده' : 'filtered out',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiTile(
                isFa ? 'بهترین پینگ' : 'Best ping',
                p.bestPingMs > 0 ? '${p.bestPingMs} ms' : '—',
                const Color(0xFF4ED8FF),
                Icons.speed_rounded,
                isFa ? 'کمترین تاخیر' : 'lowest RTT',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiTile(
                isFa ? 'سرعت دانلود' : 'Speed',
                p.avgSpeedMbps > 0
                    ? '${p.avgSpeedMbps.toStringAsFixed(0)} Mbps'
                    : '—',
                const Color(0xFFFFD24A),
                Icons.bolt_rounded,
                isFa ? 'میانگین' : 'average',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _demoTile(context, isFa),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _supportTile(context, isFa),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isFa ? '۵ پروکسی آی‌پی برتر' : 'Top 5 ProxyIPs',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: onOpenResults,
              child: Text(isFa ? 'همه نتایج' : 'All results'),
            ),
          ],
        ),
        if (topPassed.isEmpty)
          _emptyLeaderboard(isFa)
        else
          ...topPassed.map((r) => _leaderTile(context, isFa, r)),
      ],
    );
  }

  Widget _bentoShell({required Widget child, Gradient? gradient}) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? _kSurface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _heroBento(BuildContext context, bool isFa, int targetCount) {
    final isScanning = controller.isScanning;
    return _bentoShell(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF10251B), Color(0xFF0C1118)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MiliLogo(size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'miliscanner',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFa
                          ? 'اسکنر هوشمند پروکسی آی‌پی کلودفلر'
                          : 'Smart Cloudflare ProxyIP scanner',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                icon: controller.engineInfo.goAvailable
                    ? Icons.memory_rounded
                    : Icons.bolt_rounded,
                label: controller.activeEngineLabel.isEmpty
                    ? 'Go + Dart'
                    : controller.activeEngineLabel,
                color: controller.engineInfo.goAvailable
                    ? _kNeon
                    : const Color(0xFFFFD24A),
              ),
              _pill(
                icon: Icons.travel_explore_rounded,
                label: '$targetCount ${isFa ? 'هدف' : 'targets'}',
                color: const Color(0xFF4ED8FF),
              ),
              _pill(
                icon: Icons.support_agent_rounded,
                label: '@miliconfig',
                color: const Color(0xFFB388FF),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kNeon,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: isScanning ? null : controller.startScan,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    isFa ? 'شروع اسکن' : 'Start scan',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (isScanning) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: controller.togglePause,
                  icon: Icon(
                    controller.progress.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFFFF5C7A)),
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
              style: const TextStyle(color: Color(0xFFFF8A9C), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressBento(bool isFa, ScanProgress p) {
    final percent = (p.fraction * 100).toStringAsFixed(0);
    return _bentoShell(
      gradient: const LinearGradient(
        colors: [Color(0xFF111A24), Color(0xFF0B1017)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: _kNeon,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  p.phase.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${p.completed} / ${p.total}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: p.total > 0 ? p.fraction : 0,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_kNeon),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(p.elapsedMs / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              Text(
                controller.isDemo
                    ? (isFa ? 'دمو — داده آزمایشی' : 'demo data')
                    : (isFa ? 'موتور همزمان' : 'concurrent engine'),
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(
    String label,
    String value,
    Color accent,
    IconData icon,
    String hint,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurfaceAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(fontSize: 10.5, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _demoTile(BuildContext context, bool isFa) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        if (controller.isDemo) {
          controller.clearResults();
        } else {
          await controller.loadDemoResults();
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              controller.isDemo
                  ? (isFa ? '۱۸ نتیجه دمویی بارگذاری شد.' : '18 demo results loaded.')
                  : (isFa ? 'دمو پاک شد.' : 'Demo cleared.'),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B2C3D), Color(0xFF101821)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4ED8FF)),
            const SizedBox(height: 10),
            Text(
              controller.isDemo
                  ? (isFa ? 'پاک کردن دمو' : 'Clear demo')
                  : (isFa ? 'نمایش دمو ۱۸ نتیجه' : 'Preview 18 results'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              isFa ? 'چیدمان را بدون اسکن ببینید' : 'Browse the layout instantly',
              style: const TextStyle(fontSize: 10.5, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportTile(BuildContext context, bool isFa) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => launchUrl(
        Uri.parse('https://t.me/miliconfig'),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1226),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFB388FF).withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.forum_rounded, color: Color(0xFFB388FF)),
            const SizedBox(height: 10),
            Text(
              isFa ? 'پشتیبانی' : 'Support',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 2),
            const Text(
              '@miliconfig',
              style: TextStyle(fontSize: 10.5, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyLeaderboard(bool isFa) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radar_rounded, color: Colors.white24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isFa
                  ? 'دکمه «شروع اسکن» را بزنید یا یک دمو بارگذاری کنید.'
                  : 'Tap Start scan, or load a demo to preview the layout.',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderTile(BuildContext context, bool isFa, ScanResult r) {
    final meta = ProxyDatabase.metaFor(r.country);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Text(meta.flag, style: const TextStyle(fontSize: 22)),
        title: Text(
          r.endpoint,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          '${r.provider} • ${r.colo.isEmpty ? 'CF' : r.colo} • ${r.isIpv6 ? "IPv6" : "IPv4"}',
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${r.avgLatencyMs} ms',
              style: const TextStyle(color: _kNeon, fontWeight: FontWeight.w800),
            ),
            Text(
              '★ ${r.score.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        onTap: () {
          Clipboard.setData(ClipboardData(text: r.endpoint));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFa ? 'کپی شد: ${r.endpoint}' : 'Copied: ${r.endpoint}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _pill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

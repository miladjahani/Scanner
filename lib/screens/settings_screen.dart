import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/scanner_controller.dart';
import '../widgets/mili_logo.dart';

class SettingsScreen extends StatefulWidget {
  final ScannerController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _sniCtrl;
  late TextEditingController _traceHostCtrl;
  late TextEditingController _colosCtrl;
  late TextEditingController _portsCtrl;
  late TextEditingController _vlessUuidCtrl;
  late TextEditingController _vlessHostCtrl;
  late TextEditingController _vlessPathCtrl;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  void _syncControllers() {
    final cfg = widget.controller.config;
    _sniCtrl = TextEditingController(text: cfg.sni);
    _traceHostCtrl = TextEditingController(text: cfg.traceHost);
    _colosCtrl = TextEditingController(text: cfg.allowedColos.join(','));
    _portsCtrl = TextEditingController(text: cfg.defaultPorts.join(','));
    _vlessUuidCtrl = TextEditingController(text: cfg.vlessUuid);
    _vlessHostCtrl = TextEditingController(text: cfg.vlessHost);
    _vlessPathCtrl = TextEditingController(text: cfg.vlessPath);
  }

  @override
  void dispose() {
    _sniCtrl.dispose();
    _traceHostCtrl.dispose();
    _colosCtrl.dispose();
    _portsCtrl.dispose();
    _vlessUuidCtrl.dispose();
    _vlessHostCtrl.dispose();
    _vlessPathCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSupportChannel() async {
    await launchUrl(
      Uri.parse('https://t.me/miliconfig'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final cfg = c.config;
    final isFa = c.isFa;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(isFa ? '۱. موتور اسکن و همزمانی' : '1. Engine & Concurrency'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isFa ? 'اولویت با هسته بومی Go (gomobile)' : 'Prefer Native Go Engine'),
                  subtitle: Text(
                    c.engineInfo.goAvailable
                        ? (isFa ? 'هسته Go آماده است (${c.engineInfo.version})' : 'Go AAR Ready (${c.engineInfo.version})')
                        : (isFa ? 'فایل AAR بیلد نشده — از موتور Dart استفاده می‌شود' : 'Go AAR absent — using Dart fallback'),
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: cfg.preferGoEngine,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(preferGoEngine: v)),
                ),
                _sliderRow(
                  label: isFa ? 'تعداد ترد همزمان (Concurrency)' : 'Worker Threads',
                  valueText: '${cfg.concurrency}',
                  value: cfg.concurrency.toDouble(),
                  min: 4,
                  max: 256,
                  divisions: 63,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(concurrency: v.round())),
                ),
                _sliderRow(
                  label: isFa ? 'تایم‌اوت هر تست (Timeout)' : 'Probe Timeout',
                  valueText: '${cfg.timeoutMs} ms',
                  value: cfg.timeoutMs.toDouble(),
                  min: 500,
                  max: 8000,
                  divisions: 30,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(timeoutMs: v.round())),
                ),
                _sliderRow(
                  label: isFa ? 'تعداد پراب TCP برای هر IP' : 'TCP Probes per IP',
                  valueText: '${cfg.probeCount}',
                  value: cfg.probeCount.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(probeCount: v.round())),
                ),
                _sliderRow(
                  label: isFa ? 'حداکثر IP از هر رنج CIDR' : 'Max IPs per CIDR',
                  valueText: '${cfg.maxIpsPerCidr}',
                  value: cfg.maxIpsPerCidr.toDouble(),
                  min: 16,
                  max: 1024,
                  divisions: 63,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(maxIpsPerCidr: v.round())),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionHeader(isFa ? '۲. پروتکل، TLS و بررسی Trace کلودفلر' : '2. Protocol, TLS & Cloudflare Trace'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isFa ? 'تست Handshake TLS' : 'Verify TLS Handshake'),
                  value: cfg.verifyTls,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(verifyTls: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isFa ? 'بررسی /cdn-cgi/trace (تشخیص Colo)' : 'Verify /cdn-cgi/trace (Colo Detection)'),
                  value: cfg.verifyTrace,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(verifyTrace: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isFa ? 'الزام به تایید Trace کلودفلر' : 'Require Valid CF Trace'),
                  value: cfg.requireCfTrace,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(requireCfTrace: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isFa ? 'رد کردن خطای گواهی SSL روی IP خام' : 'Skip SSL Cert Verification'),
                  value: cfg.insecureSkipCert,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(insecureSkipCert: v)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lan_rounded, color: Color(0xFFB388FF)),
                  title: Text(isFa ? 'پشتیبانی خودکار IPv4 و IPv6' : 'Automatic IPv4 & IPv6 support'),
                  subtitle: Text(
                    isFa
                        ? 'آدرس‌های IPv6 و رنج‌های CIDR نسخه ۶ به‌صورت خودکار شناسایی و اسکن می‌شوند.'
                        : 'IPv6 literals and /48-style IPv6 CIDR blocks are detected and scanned automatically.',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sniCtrl,
                  decoration: InputDecoration(
                    labelText: 'TLS SNI',
                    isDense: true,
                  ),
                  onChanged: (v) => c.updateConfig(cfg.copyWith(sni: v.trim())),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _traceHostCtrl,
                  decoration: InputDecoration(
                    labelText: 'Trace Host Header',
                    isDense: true,
                  ),
                  onChanged: (v) => c.updateConfig(cfg.copyWith(traceHost: v.trim())),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _portsCtrl,
                  decoration: InputDecoration(
                    labelText: isFa ? 'پورت‌های پیش‌فرض (با کاما)' : 'Default Ports (comma-separated)',
                    hintText: '443,8443,2053,2083,2087,2096',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final parsed = v
                        .split(',')
                        .map((e) => int.tryParse(e.trim()))
                        .whereType<int>()
                        .where((p) => p > 0 && p <= 65535)
                        .toList();
                    if (parsed.isNotEmpty) {
                      c.updateConfig(cfg.copyWith(defaultPorts: parsed));
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: cfg.minTlsVersion,
                  decoration: InputDecoration(
                    labelText: isFa ? 'حداقل نسخه TLS' : 'Minimum TLS Version',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: '1.2', child: Text('TLS 1.2')),
                    DropdownMenuItem(value: '1.3', child: Text('TLS 1.3')),
                  ],
                  onChanged: (v) {
                    if (v != null) c.updateConfig(cfg.copyWith(minTlsVersion: v));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionHeader(isFa ? '۳. تست سرعت دانلود (Speed Test)' : '3. Download Speed Test'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isFa ? 'فعال‌سازی تست سرعت دانلود' : 'Enable Download Speed Test'),
                  subtitle: Text(
                    isFa
                        ? 'روی بهترین آی‌پی‌های مرحله اول اجرا می‌شود'
                        : 'Runs on lowest-latency candidates after phase 1',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: cfg.enableSpeedTest,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(enableSpeedTest: v)),
                ),
                DropdownButtonFormField<int>(
                  value: [131072, 524288, 1048576, 5242880].contains(cfg.speedTestBytes)
                      ? cfg.speedTestBytes
                      : 524288,
                  decoration: InputDecoration(
                    labelText: isFa ? 'حجم فایل تست سرعت' : 'Payload Size',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 131072, child: Text('128 KB (Fast)')),
                    DropdownMenuItem(value: 524288, child: Text('512 KB (Balanced)')),
                    DropdownMenuItem(value: 1048576, child: Text('1 MB (Accurate)')),
                    DropdownMenuItem(value: 5242880, child: Text('5 MB (Heavy)')),
                  ],
                  onChanged: (v) {
                    if (v != null) c.updateConfig(cfg.copyWith(speedTestBytes: v));
                  },
                ),
                const SizedBox(height: 8),
                _sliderRow(
                  label: isFa ? 'تعداد آی‌پی برتر برای تست سرعت' : 'Speed-Test Top N IPs',
                  valueText: '${cfg.speedTestTopN}',
                  value: cfg.speedTestTopN.toDouble(),
                  min: 5,
                  max: 50,
                  divisions: 9,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(speedTestTopN: v.round())),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionHeader(isFa ? '۴. آستانه‌های کیفیت و فیلتر Colo' : '4. Quality Thresholds & Colo Filter'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _sliderRow(
                  label: isFa ? 'حداکثر پینگ مجاز' : 'Max Latency',
                  valueText: '${cfg.maxLatencyMs} ms',
                  value: cfg.maxLatencyMs.toDouble(),
                  min: 100,
                  max: 3000,
                  divisions: 29,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(maxLatencyMs: v.round())),
                ),
                _sliderRow(
                  label: isFa ? 'حداکثر جیتر مجاز' : 'Max Jitter',
                  valueText: '${cfg.maxJitterMs} ms',
                  value: cfg.maxJitterMs.toDouble(),
                  min: 20,
                  max: 1000,
                  divisions: 49,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(maxJitterMs: v.round())),
                ),
                _sliderRow(
                  label: isFa ? 'حداکثر پکت‌لاس مجاز' : 'Max Packet Loss',
                  valueText: '${cfg.maxPacketLossPct.toStringAsFixed(0)}%',
                  value: cfg.maxPacketLossPct,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) => c.updateConfig(cfg.copyWith(maxPacketLossPct: v)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _colosCtrl,
                  decoration: InputDecoration(
                    labelText: isFa ? 'فیلتر کد دیتاسنتر کلودفلر (اختیاری)' : 'Allowed CF Colos (optional)',
                    hintText: 'FRA,AMS,LHR,SIN',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final list = v
                        .split(',')
                        .map((e) => e.trim().toUpperCase())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    c.updateConfig(cfg.copyWith(allowedColos: list));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionHeader(isFa ? '۵. قالب خروجی VLESS' : '5. VLESS Export Template'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: _vlessUuidCtrl,
                  decoration: const InputDecoration(labelText: 'VLESS UUID', isDense: true),
                  onChanged: (v) => c.updateConfig(cfg.copyWith(vlessUuid: v.trim())),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _vlessHostCtrl,
                  decoration: const InputDecoration(labelText: 'Worker Host / SNI', isDense: true),
                  onChanged: (v) => c.updateConfig(cfg.copyWith(vlessHost: v.trim())),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _vlessPathCtrl,
                  decoration: const InputDecoration(labelText: 'WebSocket Path', isDense: true),
                  onChanged: (v) => c.updateConfig(cfg.copyWith(vlessPath: v.trim())),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionHeader(isFa ? '۶. پشتیبانی' : '6. Support'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.telegram_rounded, color: Color(0xFF29B6F6)),
            title: const Text('@miliconfig'),
            subtitle: Text(
              isFa ? 'کانال پشتیبانی و اطلاع‌رسانی miliscanner' : 'miliscanner support & updates channel',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: _openSupportChannel,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const MiliLogo(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'miliscanner',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFa
                            ? 'نسخه ۱.۰.۱ • کانال پشتیبانی: @miliconfig'
                            : 'v1.0.1 • support channel: @miliconfig',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
          onPressed: () async {
            await c.resetConfig();
            setState(() {
              _sniCtrl.text = c.config.sni;
              _traceHostCtrl.text = c.config.traceHost;
              _colosCtrl.text = c.config.allowedColos.join(',');
              _portsCtrl.text = c.config.defaultPorts.join(',');
              _vlessUuidCtrl.text = c.config.vlessUuid;
              _vlessHostCtrl.text = c.config.vlessHost;
              _vlessPathCtrl.text = c.config.vlessPath;
            });
          },
          icon: const Icon(Icons.restore_rounded),
          label: Text(isFa ? 'بازنشانی تمام تنظیمات به پیش‌فرض' : 'Reset All Settings to Defaults'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Color(0xFF00E676),
          ),
        ),
      );

  Widget _sliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              valueText,
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFF00E676),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

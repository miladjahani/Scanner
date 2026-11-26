import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/proxy_database.dart';
import '../state/scanner_controller.dart';

class CountriesScreen extends StatefulWidget {
  final ScannerController controller;
  const CountriesScreen({super.key, required this.controller});

  @override
  State<CountriesScreen> createState() => _CountriesScreenState();
}

class _CountriesScreenState extends State<CountriesScreen> {
  late final TextEditingController _customCtrl;
  final TextEditingController _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customCtrl = TextEditingController(text: widget.controller.customTargetsText);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv'],
    );
    if (result == null || result.files.single.path == null) return;
    final content = await File(result.files.single.path!).readAsString();
    final merged = _customCtrl.text.trim().isEmpty
        ? content.trim()
        : '${_customCtrl.text.trim()}\n${content.trim()}';
    _customCtrl.text = merged;
    await widget.controller.setCustomTargetsText(merged);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isFa = c.isFa;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Region Quick Filters + GitHub Sync
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFa ? 'انتخاب سریع مناطق و همگام‌سازی گیت‌هاب' : 'Quick Regions & GitHub Sync',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: Text(isFa ? 'همه' : 'All'),
                      onPressed: () => c.selectCountryGroup('ALL'),
                    ),
                    ActionChip(
                      label: Text(isFa ? 'اروپا' : 'Europe'),
                      onPressed: () => c.selectCountryGroup('EU'),
                    ),
                    ActionChip(
                      label: Text(isFa ? 'خاورمیانه' : 'Middle East'),
                      onPressed: () => c.selectCountryGroup('ME'),
                    ),
                    ActionChip(
                      label: Text(isFa ? 'آمریکا' : 'Americas'),
                      onPressed: () => c.selectCountryGroup('AM'),
                    ),
                    ActionChip(
                      label: Text(isFa ? 'آسیا' : 'Asia'),
                      onPressed: () => c.selectCountryGroup('AS'),
                    ),
                    ActionChip(
                      label: Text(isFa ? 'پاک کردن' : 'Clear'),
                      onPressed: () => c.selectCountryGroup('NONE'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: c.isSyncing
                        ? null
                        : () async {
                            final count = await c.syncSelectedFromGitHub();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFa
                                      ? '$count پروکسی آی‌پی جدید از گیت‌هاب دریافت شد.'
                                      : 'Synced $count fresh ProxyIPs from GitHub.',
                                ),
                              ),
                            );
                          },
                    icon: c.isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_outlined),
                    label: Text(
                      isFa
                          ? 'به‌روزرسانی آنلاین لیست کشورهای انتخاب‌شده از گیت‌هاب'
                          : 'Sync Selected Countries from GitHub',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Country Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ProxyDatabase.countries.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.35,
          ),
          itemBuilder: (context, idx) {
            final meta = ProxyDatabase.countries[idx];
            final selected = c.selectedCountries.contains(meta.code);
            final builtInCount = ProxyDatabase.builtInByCountry[meta.code]?.length ?? 0;
            final syncedCount = c.syncedCountryTargets[meta.code]?.length ?? 0;
            final total = syncedCount > 0 ? syncedCount : builtInCount;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => c.toggleCountry(meta.code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF00E676).withValues(alpha: 0.14)
                      : const Color(0xFF10161F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF00E676)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Text(meta.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFa ? meta.nameFa : meta.nameEn,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            '${meta.code} • $total IP',
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 18),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Custom IP / CIDR Input & File/URL Import
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFa ? 'لیست دلخواه (IP:Port، CSV یا رنج CIDR)' : 'Custom IPs / CSV / CIDR Ranges',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customCtrl,
                  maxLines: 5,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    hintText: '18.184.55.249:443\n162.158.82.0/24\n116.203.58.165,443,DE,Hetzner',
                  ),
                  onChanged: (v) => c.setCustomTargetsText(v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _importFromFile,
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: Text(isFa ? 'ورود از فایل' : 'Import File'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _customCtrl.clear();
                          c.setCustomTargetsText('');
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(isFa ? 'پاک کردن' : 'Clear'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlCtrl,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: isFa ? 'لینک خام (Raw URL) گیت‌هاب...' : 'Custom Raw URL...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: c.isSyncing
                          ? null
                          : () async {
                              if (_urlCtrl.text.trim().isEmpty) return;
                              final n = await c.syncFromCustomUrl(_urlCtrl.text.trim());
                              _customCtrl.text = c.customTargetsText;
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isFa ? '$n آدرس اضافه شد' : 'Added $n targets')),
                              );
                            },
                      child: Text(isFa ? 'دریافت' : 'Fetch'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Dynamic ProxyIP Domains
        Text(
          isFa ? 'دامین‌های پروکسی آی‌پی پویا (کپی سریع)' : 'Dynamic ProxyIP Domains (Tap to Copy)',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...ProxyDatabase.dynamicDomains.map(
          (d) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              title: Text(d.domain, style: const TextStyle(fontFamily: 'monospace')),
              subtitle: Text('${d.country} • ${d.note}', style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF00E676)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: d.domain));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isFa ? 'کپی شد: ${d.domain}' : 'Copied: ${d.domain}')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

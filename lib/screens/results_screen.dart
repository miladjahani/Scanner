import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/proxy_database.dart';
import '../models/scan_models.dart';
import '../services/export_service.dart';
import '../state/scanner_controller.dart';

const Color _kNeon = Color(0xFF00E676);
const Color _kSurface = Color(0xFF0E141C);
const Color _kSurfaceAlt = Color(0xFF121B25);

class ResultsScreen extends StatelessWidget {
  final ScannerController controller;
  const ResultsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isFa = controller.isFa;
    final results = controller.filteredResults;
    final availableCountries = <String>{
      'ALL',
      ...controller.allResults.map((e) => e.country),
    }.toList()
      ..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        hintText: isFa
                            ? 'جستجو IP، کشور، Colo...'
                            : 'Search IP, country, colo...',
                      ),
                      onChanged: controller.setFilterQuery,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: results.isEmpty
                        ? null
                        : () => _showExportSheet(context, results),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(isFa ? 'خروجی' : 'Export'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(isFa ? 'فقط سالم‌ها' : 'Passed only'),
                      selected: controller.onlyPassed,
                      onSelected: controller.setOnlyPassed,
                    ),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: availableCountries.contains(controller.filterCountry)
                          ? controller.filterCountry
                          : 'ALL',
                      underline: const SizedBox.shrink(),
                      items: availableCountries
                          .map((cc) => DropdownMenuItem(
                                value: cc,
                                child: Text(cc == 'ALL'
                                    ? (isFa ? 'همه کشورها' : 'All countries')
                                    : cc),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) controller.setFilterCountry(v);
                      },
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<ResultSortBy>(
                      value: controller.sortBy,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                            value: ResultSortBy.score,
                            child: Text(isFa ? 'امتیاز' : 'Score')),
                        DropdownMenuItem(
                            value: ResultSortBy.latency,
                            child: Text(isFa ? 'پینگ' : 'Ping')),
                        DropdownMenuItem(
                            value: ResultSortBy.jitter,
                            child: Text(isFa ? 'جیتر' : 'Jitter')),
                        DropdownMenuItem(
                            value: ResultSortBy.speed,
                            child: Text(isFa ? 'سرعت' : 'Speed')),
                        DropdownMenuItem(
                            value: ResultSortBy.country,
                            child: Text(isFa ? 'کشور' : 'Country')),
                      ],
                      onChanged: (v) {
                        if (v != null) controller.setSortBy(v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (controller.isDemo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: Color(0xFF4ED8FF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isFa
                        ? 'این نتایج دمویی هستند؛ برای داده واقعی اسکن کنید.'
                        : 'These results are demo data — run a scan for live IPs.',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: controller.clearResults,
                  child: Text(isFa ? 'پاک کردن' : 'Clear'),
                ),
              ],
            ),
          ),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Text(
                    isFa
                        ? 'نتیجه‌ای برای نمایش وجود ندارد.'
                        : 'No results match current filters.',
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: results.length,
                  itemBuilder: (context, idx) {
                    final r = results[idx];
                    final meta = ProxyDatabase.metaFor(r.country);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _kSurfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        leading: Text(meta.flag, style: const TextStyle(fontSize: 22)),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.endpoint,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            if (r.isIpv6)
                              _badge('IPv6', const Color(0xFFB388FF)),
                            if (r.colo.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _badge(r.colo, const Color(0xFF4ED8FF)),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          r.passed
                              ? '${r.provider} • Jitter ${r.jitterMs}ms • Loss ${r.packetLossPct}%${r.downloadMbps > 0 ? " • ${r.downloadMbps} Mbps" : ""}'
                              : '${r.provider} • ${r.failReason}',
                          style: TextStyle(
                            fontSize: 11,
                            color: r.passed ? Colors.white60 : Colors.redAccent,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              r.passed ? '${r.avgLatencyMs} ms' : 'FAIL',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: r.passed ? _kNeon : Colors.redAccent,
                              ),
                            ),
                            if (r.passed)
                              Text(
                                '★ ${r.score}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.amberAccent,
                                ),
                              ),
                          ],
                        ),
                        onTap: () => _showDetailModal(context, r),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  void _showDetailModal(BuildContext context, ScanResult r) {
    final isFa = controller.isFa;
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.endpoint,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kNeon,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              r.isIpv6 ? 'IPv6' : 'IPv4',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
            const SizedBox(height: 10),
            _kv('Country / Provider', '${r.country} • ${r.provider}'),
            _kv('Latency (Min / Avg / Max)',
                '${r.minLatencyMs} / ${r.avgLatencyMs} / ${r.maxLatencyMs} ms'),
            _kv('Jitter / Packet Loss', '${r.jitterMs} ms • ${r.packetLossPct}%'),
            _kv('TLS Handshake / Ver',
                '${r.tlsHandshakeMs} ms • ${r.tlsVersion} (${r.negotiatedAlpn})'),
            _kv('CF Trace',
                r.traceOk ? 'OK • ${r.colo} • ${r.traceLoc}' : 'N/A'),
            _kv('Download', r.downloadMbps > 0 ? '${r.downloadMbps} Mbps' : 'n/a'),
            _kv('Score', '${r.score} / 100'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: r.endpoint));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFa
                              ? 'کپی شد: ${r.endpoint}'
                              : 'Copied: ${r.endpoint}'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(isFa ? 'کپی IP:Port' : 'Copy IP:Port'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: r.ip));
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.link_rounded),
                    label: Text(isFa ? 'کپی IP' : 'Copy IP'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      );

  void _showExportSheet(BuildContext context, List<ScanResult> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      builder: (_) => ExportSheet(
        results: results,
        controller: controller,
      ),
    );
  }
}

/// Export sheet: pick a container plus the requested output toggles
/// (comma / new lines, with / without port, country hashtags, IPv6 only).
class ExportSheet extends StatefulWidget {
  final List<ScanResult> results;
  final ScannerController controller;

  const ExportSheet({
    super.key,
    required this.results,
    required this.controller,
  });

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  ExportFormat _format = ExportFormat.list;
  ExportOptions _options = const ExportOptions();

  String get _content => ExportService.formatResults(
        widget.results,
        _format,
        config: widget.controller.config,
        options: _options,
      );

  @override
  Widget build(BuildContext context) {
    final isFa = widget.controller.isFa;
    final preview = _content.split('\n').take(6).join('\n');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFa ? 'خروجی آی‌پی‌های سالم' : 'Export passing IPs',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExportFormat.values.map((fmt) {
                  final label = switch (fmt) {
                    ExportFormat.list => isFa ? 'لیست' : 'List',
                    ExportFormat.csv => 'CSV',
                    ExportFormat.json => 'JSON',
                    ExportFormat.vless => 'VLESS',
                  };
                  return ChoiceChip(
                    label: Text(label),
                    selected: _format == fmt,
                    onSelected: (_) => setState(() => _format = fmt),
                  );
                }).toList(),
              ),
              if (_format == ExportFormat.list) ...[
                const SizedBox(height: 12),
                Text(
                  isFa ? 'جداکننده' : 'Separator',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 6),
                SegmentedButton<ExportSeparator>(
                  segments: [
                    ButtonSegment(
                      value: ExportSeparator.newLine,
                      label: Text(isFa ? 'هر آی‌پی یک خط' : 'One per line'),
                      icon: const Icon(Icons.format_list_bulleted_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ExportSeparator.comma,
                      label: Text(isFa ? 'با کاما' : 'Comma'),
                      icon: const Icon(Icons.drag_handle_rounded, size: 16),
                    ),
                  ],
                  selected: {_options.separator},
                  onSelectionChanged: (s) => setState(
                    () => _options = _options.copyWith(separator: s.first),
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(isFa ? 'همراه با پورت' : 'Include port'),
                subtitle: Text(
                  isFa ? 'مثل 1.2.3.4:443' : 'e.g. 1.2.3.4:443',
                  style: const TextStyle(fontSize: 10.5),
                ),
                value: _options.includePort,
                onChanged: (v) => setState(
                  () => _options = _options.copyWith(includePort: v),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(isFa ? 'هشتگ کشور' : 'Country hashtags'),
                subtitle: Text(
                  isFa ? 'گروه‌بندی با #DE، #NL و…' : 'Group under #DE, #NL, …',
                  style: const TextStyle(fontSize: 10.5),
                ),
                value: _options.includeCountryTag,
                onChanged: (v) => setState(
                  () => _options = _options.copyWith(includeCountryTag: v),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(isFa ? 'فقط IPv6' : 'IPv6 only'),
                subtitle: Text(
                  isFa ? 'آی‌پی‌های ۶ را جدا کنید' : 'Keep IPv6 results only',
                  style: const TextStyle(fontSize: 10.5),
                ),
                value: _options.onlyIpv6,
                onChanged: (v) => setState(
                  () => _options = _options.copyWith(onlyIpv6: v),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF070B10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  preview.isEmpty ? (isFa ? 'داده‌ای نیست' : 'nothing to export') : preview,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _content));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isFa ? 'کپی شد.' : 'Copied.')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(isFa ? 'کپی' : 'Copy'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ExportService.shareExport(
                          widget.results,
                          _format,
                          config: widget.controller.config,
                          options: _options,
                        );
                      },
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(isFa ? 'اشتراک فایل' : 'Share file'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

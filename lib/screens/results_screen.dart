import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/proxy_database.dart';
import '../models/scan_models.dart';
import '../services/export_service.dart';
import '../state/scanner_controller.dart';

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
        // Filter & Sort Toolbar
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
                        hintText: isFa ? 'جستجو IP، کشور، Colo یا سرویس‌دهنده...' : 'Search IP, country, colo...',
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
                      label: Text(isFa ? 'فقط سالم‌ها' : 'Passed Only'),
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
                                child: Text(cc == 'ALL' ? (isFa ? 'همه کشورها' : 'All Countries') : cc),
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
                        DropdownMenuItem(value: ResultSortBy.score, child: Text(isFa ? 'امتیاز' : 'Score')),
                        DropdownMenuItem(value: ResultSortBy.latency, child: Text(isFa ? 'پینگ' : 'Ping')),
                        DropdownMenuItem(value: ResultSortBy.jitter, child: Text(isFa ? 'جیتر' : 'Jitter')),
                        DropdownMenuItem(value: ResultSortBy.speed, child: Text(isFa ? 'سرعت' : 'Speed')),
                        DropdownMenuItem(value: ResultSortBy.country, child: Text(isFa ? 'کشور' : 'Country')),
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
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Text(
                    isFa ? 'نتیجه‌ای برای نمایش وجود ندارد.' : 'No results match current filters.',
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: results.length,
                  itemBuilder: (context, idx) {
                    final r = results[idx];
                    final meta = ProxyDatabase.metaFor(r.country);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Text(meta.flag, style: const TextStyle(fontSize: 22)),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                r.endpoint,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (r.colo.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r.colo,
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
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
                                color: r.passed ? const Color(0xFF00E676) : Colors.redAccent,
                              ),
                            ),
                            if (r.passed)
                              Text(
                                '★ ${r.score}',
                                style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
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

  void _showDetailModal(BuildContext context, ScanResult r) {
    final isFa = controller.isFa;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10161F),
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
                color: Color(0xFF00E676),
              ),
            ),
            const SizedBox(height: 10),
            _kv('Country / Provider', '${r.country} • ${r.provider}'),
            _kv('Latency (Min / Avg / Max)', '${r.minLatencyMs} / ${r.avgLatencyMs} / ${r.maxLatencyMs} ms'),
            _kv('Jitter / Packet Loss', '${r.jitterMs} ms • ${r.packetLossPct}%'),
            _kv('TLS Handshake / Ver', '${r.tlsHandshakeMs} ms • ${r.tlsVersion} (${r.negotiatedAlpn})'),
            _kv('Cloudflare Trace', r.traceOk ? 'OK • Colo: ${r.colo} • Loc: ${r.traceLoc}' : 'N/A'),
            _kv('Download Speed', r.downloadMbps > 0 ? '${r.downloadMbps} Mbps' : 'Not tested'),
            _kv('Composite Score', '${r.score} / 100'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: r.endpoint));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isFa ? 'کپی شد: ${r.endpoint}' : 'Copied: ${r.endpoint}')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(isFa ? 'کپی IP:Port' : 'Copy IP:Port'),
              ),
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
    final isFa = controller.isFa;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10161F),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFa ? 'خروجی و کپی نتایج سالم' : 'Export & Copy Passing Results',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...ExportFormat.values.map((fmt) {
              return ListTile(
                title: Text(fmt.name.toUpperCase()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        final text = ExportService.formatResults(
                          results,
                          fmt,
                          config: controller.config,
                        );
                        Clipboard.setData(ClipboardData(text: text));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFa ? 'خروجی ${fmt.name.toUpperCase()} کپی شد.' : 'Copied ${fmt.name.toUpperCase()}.',
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Color(0xFF00E676)),
                      onPressed: () async {
                        Navigator.pop(context);
                        await ExportService.shareExport(
                          results,
                          fmt,
                          config: controller.config,
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

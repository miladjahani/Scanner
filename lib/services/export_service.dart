import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_models.dart';

class ExportService {
  static String formatResults(
    List<ScanResult> results,
    ExportFormat format, {
    required ScanConfig config,
  }) {
    final passing = results.where((r) => r.passed).toList();
    switch (format) {
      case ExportFormat.txt:
        return passing.map((r) => '${r.ip}:${r.port}').join('\n');

      case ExportFormat.bpb:
        return passing.map((r) => '${r.ip}:${r.port}').join(',');

      case ExportFormat.csv:
        final buf = StringBuffer();
        buf.writeln(
          'IP,Port,Country,Provider,AvgLatencyMs,JitterMs,LossPct,TLSHandshakeMs,Colo,DownloadMbps,Score',
        );
        for (final r in passing) {
          final safeProv = r.provider.replaceAll(',', ' ');
          buf.writeln(
            '${r.ip},${r.port},${r.country},$safeProv,${r.avgLatencyMs},${r.jitterMs},${r.packetLossPct},${r.tlsHandshakeMs},${r.colo},${r.downloadMbps},${r.score}',
          );
        }
        return buf.toString();

      case ExportFormat.json:
        return const JsonEncoder.withIndent('  ')
            .convert(passing.map((r) => r.toJson()).toList());

      case ExportFormat.vless:
        final encodedPath = Uri.encodeComponent(config.vlessPath);
        return passing.map((r) {
          final tag = Uri.encodeComponent('${r.country}-${r.colo.isEmpty ? "CF" : r.colo}-${r.avgLatencyMs}ms');
          return 'vless://${config.vlessUuid}@${r.ip}:${r.port}'
              '?encryption=none&security=tls&sni=${config.vlessHost}'
              '&fp=chrome&type=ws&host=${config.vlessHost}&path=$encodedPath#$tag';
        }).join('\n');
    }
  }

  static String extensionFor(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.json:
        return 'json';
      case ExportFormat.txt:
      case ExportFormat.bpb:
      case ExportFormat.vless:
        return 'txt';
    }
  }

  static Future<void> shareExport(
    List<ScanResult> results,
    ExportFormat format, {
    required ScanConfig config,
  }) async {
    final content = formatResults(results, format, config: config);
    final dir = await getTemporaryDirectory();
    final ext = extensionFor(format);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/edgepulse_proxies_${format.name}_$ts.$ext');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'EdgePulse ProxyIP Export (${format.name.toUpperCase()})',
    );
  }
}

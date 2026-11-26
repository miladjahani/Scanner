import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_models.dart';

class ExportService {
  /// Renders passing results in the requested container plus output toggles.
  ///
  /// [ExportFormat.list] honours [ExportOptions.separator] (new lines or commas),
  /// [ExportOptions.includePort], [ExportOptions.includeCountryTag] (`#DE`
  /// group headers) and [ExportOptions.onlyIpv6].
  static String formatResults(
    List<ScanResult> results,
    ExportFormat format, {
    required ScanConfig config,
    ExportOptions options = const ExportOptions(),
  }) {
    final passing = _select(results, options);

    switch (format) {
      case ExportFormat.list:
        return _formatList(passing, options);

      case ExportFormat.csv:
        final buf = StringBuffer();
        buf.writeln(
          'Host,Port,Country,Provider,AvgLatencyMs,JitterMs,LossPct,TLSHandshakeMs,Colo,DownloadMbps,Score',
        );
        for (final r in passing) {
          final safeProv = r.provider.replaceAll(',', ' ');
          final host = r.isIpv6 ? formatHost(r.ip) : r.ip;
          buf.writeln(
            '$host,${r.port},${r.country},$safeProv,${r.avgLatencyMs},${r.jitterMs},${r.packetLossPct},${r.tlsHandshakeMs},${r.colo},${r.downloadMbps},${r.score}',
          );
        }
        return buf.toString();

      case ExportFormat.json:
        return const JsonEncoder.withIndent('  ')
            .convert(passing.map((r) => r.toJson()).toList());

      case ExportFormat.vless:
        final encodedPath = Uri.encodeComponent(config.vlessPath);
        return passing.map((r) {
          final tag = Uri.encodeComponent(
            '${r.country}-${r.colo.isEmpty ? 'CF' : r.colo}-${r.avgLatencyMs}ms',
          );
          return 'vless://${config.vlessUuid}@${r.endpoint}'
              '?encryption=none&security=tls&sni=${config.vlessHost}'
              '&fp=chrome&type=ws&host=${config.vlessHost}&path=$encodedPath#$tag';
        }).join('\n');
    }
  }

  static List<ScanResult> _select(List<ScanResult> results, ExportOptions options) {
    return results
        .where((r) => r.passed)
        .where((r) => !options.onlyIpv6 || r.isIpv6)
        .toList();
  }

  static String _formatList(List<ScanResult> passing, ExportOptions options) {
    String entry(ScanResult r) =>
        options.includePort ? r.endpoint : formatHost(r.ip);

    if (!options.includeCountryTag) {
      return passing.map(entry).join(_separator(options));
    }

    final grouped = <String, List<ScanResult>>{};
    for (final r in passing) {
      grouped.putIfAbsent(r.country.isEmpty ? 'XX' : r.country, () => []).add(r);
    }
    final codes = grouped.keys.toList()..sort();

    final blocks = <String>[];
    for (final code in codes) {
      final body = grouped[code]!.map(entry).join(_separator(options));
      blocks.add('#$code\n$body');
    }
    return blocks.join('\n\n');
  }

  static String _separator(ExportOptions options) =>
      options.separator == ExportSeparator.comma ? ', ' : '\n';

  static String extensionFor(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.json:
        return 'json';
      case ExportFormat.list:
      case ExportFormat.vless:
        return 'txt';
    }
  }

  /// Builds a file name that describes the active output options.
  static String fileNameFor(ExportFormat format, ExportOptions options) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final tag = [
      format.name,
      options.separator == ExportSeparator.comma ? 'comma' : 'lines',
      options.includePort ? 'port' : 'noport',
      if (options.includeCountryTag) 'tags',
    ].join('_');
    return 'miliscanner_${tag}_$ts.${extensionFor(format)}';
  }

  static Future<void> shareExport(
    List<ScanResult> results,
    ExportFormat format, {
    required ScanConfig config,
    ExportOptions options = const ExportOptions(),
  }) async {
    final content =
        formatResults(results, format, config: config, options: options);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${fileNameFor(format, options)}');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'miliscanner export (${format.name.toUpperCase()})',
    );
  }
}

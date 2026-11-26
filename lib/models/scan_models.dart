import 'dart:convert';

/// Renders a host for output: IPv6 literals are wrapped in brackets.
String formatHost(String ip) {
  final bare = ip.replaceAll('[', '').replaceAll(']', '');
  return bare.contains(':') ? '[$bare]' : bare;
}

/// Renders `host:port`, bracketing IPv6 addresses correctly.
String formatEndpoint(String ip, int port) => '${formatHost(ip)}:$port';

bool isIpv6Host(String ip) => ip.replaceAll('[', '').replaceAll(']', '').contains(':');

class ProxyTarget {
  final String ip;
  final int port;
  final String country;
  final String provider;

  const ProxyTarget({
    required this.ip,
    required this.port,
    required this.country,
    this.provider = '',
  });

  String get endpoint => formatEndpoint(ip, port);

  bool get isIpv6 => isIpv6Host(ip);

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'port': port,
        'country': country,
        'provider': provider,
      };

  factory ProxyTarget.fromJson(Map<String, dynamic> json) => ProxyTarget(
        ip: (json['ip'] ?? '').toString(),
        port: (json['port'] is int)
            ? json['port'] as int
            : int.tryParse('${json['port']}') ?? 443,
        country: (json['country'] ?? 'XX').toString().toUpperCase(),
        provider: (json['provider'] ?? '').toString(),
      );
}

class ScanConfig {
  final bool preferGoEngine;
  final int concurrency;
  final int timeoutMs;
  final int probeCount;
  final int probeDelayMs;
  final int maxIpsPerCidr;

  final List<int> defaultPorts;
  final bool verifyTls;
  final String sni;
  final String alpn;
  final String minTlsVersion;
  final bool insecureSkipCert;

  final bool verifyTrace;
  final String traceHost;
  final String tracePath;

  final bool enableSpeedTest;
  final int speedTestBytes;
  final String speedTestHost;
  final String speedTestPath;
  final int speedTestTopN;
  final int speedTestTimeoutS;

  final int maxLatencyMs;
  final int maxJitterMs;
  final double maxPacketLossPct;
  final double minDownloadMbps;
  final List<String> allowedColos;
  final bool requireCfTrace;

  final String placementRegion;
  final String vlessUuid;
  final String vlessHost;
  final String vlessPath;

  const ScanConfig({
    this.preferGoEngine = true,
    this.concurrency = 48,
    this.timeoutMs = 2500,
    this.probeCount = 3,
    this.probeDelayMs = 80,
    this.maxIpsPerCidr = 256,
    this.defaultPorts = const [443],
    this.verifyTls = true,
    this.sni = 'speed.cloudflare.com',
    this.alpn = 'h2,http/1.1',
    this.minTlsVersion = '1.2',
    this.insecureSkipCert = true,
    this.verifyTrace = true,
    this.traceHost = 'speed.cloudflare.com',
    this.tracePath = '/cdn-cgi/trace',
    this.enableSpeedTest = false,
    this.speedTestBytes = 524288,
    this.speedTestHost = 'speed.cloudflare.com',
    this.speedTestPath = '/__down?bytes=524288',
    this.speedTestTopN = 15,
    this.speedTestTimeoutS = 8,
    this.maxLatencyMs = 1200,
    this.maxJitterMs = 400,
    this.maxPacketLossPct = 35.0,
    this.minDownloadMbps = 0.0,
    this.allowedColos = const [],
    this.requireCfTrace = false,
    this.placementRegion = 'aws:eu-central-1',
    this.vlessUuid = '00000000-0000-0000-0000-000000000000',
    this.vlessHost = 'your-worker.workers.dev',
    this.vlessPath = '/?ed=2048',
  });

  ScanConfig copyWith({
    bool? preferGoEngine,
    int? concurrency,
    int? timeoutMs,
    int? probeCount,
    int? probeDelayMs,
    int? maxIpsPerCidr,
    List<int>? defaultPorts,
    bool? verifyTls,
    String? sni,
    String? alpn,
    String? minTlsVersion,
    bool? insecureSkipCert,
    bool? verifyTrace,
    String? traceHost,
    String? tracePath,
    bool? enableSpeedTest,
    int? speedTestBytes,
    String? speedTestHost,
    String? speedTestPath,
    int? speedTestTopN,
    int? speedTestTimeoutS,
    int? maxLatencyMs,
    int? maxJitterMs,
    double? maxPacketLossPct,
    double? minDownloadMbps,
    List<String>? allowedColos,
    bool? requireCfTrace,
    String? placementRegion,
    String? vlessUuid,
    String? vlessHost,
    String? vlessPath,
  }) {
    return ScanConfig(
      preferGoEngine: preferGoEngine ?? this.preferGoEngine,
      concurrency: concurrency ?? this.concurrency,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      probeCount: probeCount ?? this.probeCount,
      probeDelayMs: probeDelayMs ?? this.probeDelayMs,
      maxIpsPerCidr: maxIpsPerCidr ?? this.maxIpsPerCidr,
      defaultPorts: defaultPorts ?? this.defaultPorts,
      verifyTls: verifyTls ?? this.verifyTls,
      sni: sni ?? this.sni,
      alpn: alpn ?? this.alpn,
      minTlsVersion: minTlsVersion ?? this.minTlsVersion,
      insecureSkipCert: insecureSkipCert ?? this.insecureSkipCert,
      verifyTrace: verifyTrace ?? this.verifyTrace,
      traceHost: traceHost ?? this.traceHost,
      tracePath: tracePath ?? this.tracePath,
      enableSpeedTest: enableSpeedTest ?? this.enableSpeedTest,
      speedTestBytes: speedTestBytes ?? this.speedTestBytes,
      speedTestHost: speedTestHost ?? this.speedTestHost,
      speedTestPath: speedTestPath ?? this.speedTestPath,
      speedTestTopN: speedTestTopN ?? this.speedTestTopN,
      speedTestTimeoutS: speedTestTimeoutS ?? this.speedTestTimeoutS,
      maxLatencyMs: maxLatencyMs ?? this.maxLatencyMs,
      maxJitterMs: maxJitterMs ?? this.maxJitterMs,
      maxPacketLossPct: maxPacketLossPct ?? this.maxPacketLossPct,
      minDownloadMbps: minDownloadMbps ?? this.minDownloadMbps,
      allowedColos: allowedColos ?? this.allowedColos,
      requireCfTrace: requireCfTrace ?? this.requireCfTrace,
      placementRegion: placementRegion ?? this.placementRegion,
      vlessUuid: vlessUuid ?? this.vlessUuid,
      vlessHost: vlessHost ?? this.vlessHost,
      vlessPath: vlessPath ?? this.vlessPath,
    );
  }

  /// JSON format matching Go's `ScanConfig` struct tags verbatim.
  Map<String, dynamic> toGoJson() => {
        'concurrency': concurrency,
        'timeout_ms': timeoutMs,
        'probe_count': probeCount,
        'probe_delay_ms': probeDelayMs,
        'max_ips_per_cidr': maxIpsPerCidr,
        'default_ports': defaultPorts,
        'verify_tls': verifyTls,
        'sni': sni,
        'alpn': alpn,
        'min_tls_version': minTlsVersion,
        'insecure_skip_cert': insecureSkipCert,
        'verify_trace': verifyTrace,
        'trace_host': traceHost,
        'trace_path': tracePath,
        'enable_speed_test': enableSpeedTest,
        'speed_test_bytes': speedTestBytes,
        'speed_test_host': speedTestHost,
        'speed_test_path': '/__down?bytes=$speedTestBytes',
        'speed_test_top_n': speedTestTopN,
        'speed_test_timeout_s': speedTestTimeoutS,
        'max_latency_ms': maxLatencyMs,
        'max_jitter_ms': maxJitterMs,
        'max_packet_loss_pct': maxPacketLossPct,
        'min_download_mbps': minDownloadMbps,
        'allowed_colos': allowedColos,
        'require_cf_trace': requireCfTrace,
      };

  Map<String, dynamic> toStorageJson() => {
        ...toGoJson(),
        'prefer_go_engine': preferGoEngine,
        'placement_region': placementRegion,
        'vless_uuid': vlessUuid,
        'vless_host': vlessHost,
        'vless_path': vlessPath,
      };

  factory ScanConfig.fromJson(Map<String, dynamic> j) => ScanConfig(
        preferGoEngine: j['prefer_go_engine'] as bool? ?? true,
        concurrency: (j['concurrency'] as num?)?.toInt() ?? 48,
        timeoutMs: (j['timeout_ms'] as num?)?.toInt() ?? 2500,
        probeCount: (j['probe_count'] as num?)?.toInt() ?? 3,
        probeDelayMs: (j['probe_delay_ms'] as num?)?.toInt() ?? 80,
        maxIpsPerCidr: (j['max_ips_per_cidr'] as num?)?.toInt() ?? 256,
        defaultPorts: (j['default_ports'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [443],
        verifyTls: j['verify_tls'] as bool? ?? true,
        sni: (j['sni'] ?? 'speed.cloudflare.com').toString(),
        alpn: (j['alpn'] ?? 'h2,http/1.1').toString(),
        minTlsVersion: (j['min_tls_version'] ?? '1.2').toString(),
        insecureSkipCert: j['insecure_skip_cert'] as bool? ?? true,
        verifyTrace: j['verify_trace'] as bool? ?? true,
        traceHost: (j['trace_host'] ?? 'speed.cloudflare.com').toString(),
        tracePath: (j['trace_path'] ?? '/cdn-cgi/trace').toString(),
        enableSpeedTest: j['enable_speed_test'] as bool? ?? false,
        speedTestBytes: (j['speed_test_bytes'] as num?)?.toInt() ?? 524288,
        speedTestHost:
            (j['speed_test_host'] ?? 'speed.cloudflare.com').toString(),
        speedTestPath:
            (j['speed_test_path'] ?? '/__down?bytes=524288').toString(),
        speedTestTopN: (j['speed_test_top_n'] as num?)?.toInt() ?? 15,
        speedTestTimeoutS: (j['speed_test_timeout_s'] as num?)?.toInt() ?? 8,
        maxLatencyMs: (j['max_latency_ms'] as num?)?.toInt() ?? 1200,
        maxJitterMs: (j['max_jitter_ms'] as num?)?.toInt() ?? 400,
        maxPacketLossPct:
            (j['max_packet_loss_pct'] as num?)?.toDouble() ?? 35.0,
        minDownloadMbps: (j['min_download_mbps'] as num?)?.toDouble() ?? 0.0,
        allowedColos: (j['allowed_colos'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        requireCfTrace: j['require_cf_trace'] as bool? ?? false,
        placementRegion:
            (j['placement_region'] ?? 'aws:eu-central-1').toString(),
        vlessUuid: (j['vless_uuid'] ?? '00000000-0000-0000-0000-000000000000')
            .toString(),
        vlessHost: (j['vless_host'] ?? 'your-worker.workers.dev').toString(),
        vlessPath: (j['vless_path'] ?? '/?ed=2048').toString(),
      );
}

class ScanResult {
  final String ip;
  final int port;
  final String country;
  final String provider;
  final bool passed;
  final String failReason;
  final int minLatencyMs;
  final int avgLatencyMs;
  final int maxLatencyMs;
  final int jitterMs;
  final double packetLossPct;
  final int tlsHandshakeMs;
  final String tlsVersion;
  final String negotiatedAlpn;
  final bool traceOk;
  final String colo;
  final String traceLoc;
  final String traceIp;
  final double downloadMbps;
  final double score;
  final int timestampUnix;

  const ScanResult({
    required this.ip,
    required this.port,
    required this.country,
    this.provider = '',
    required this.passed,
    this.failReason = '',
    this.minLatencyMs = 0,
    this.avgLatencyMs = 0,
    this.maxLatencyMs = 0,
    this.jitterMs = 0,
    this.packetLossPct = 0,
    this.tlsHandshakeMs = 0,
    this.tlsVersion = '',
    this.negotiatedAlpn = '',
    this.traceOk = false,
    this.colo = '',
    this.traceLoc = '',
    this.traceIp = '',
    this.downloadMbps = 0,
    this.score = 0,
    this.timestampUnix = 0,
  });

  String get endpoint => formatEndpoint(ip, port);

  bool get isIpv6 => isIpv6Host(ip);

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'port': port,
        'country': country,
        'provider': provider,
        'passed': passed,
        'fail_reason': failReason,
        'min_latency_ms': minLatencyMs,
        'avg_latency_ms': avgLatencyMs,
        'max_latency_ms': maxLatencyMs,
        'jitter_ms': jitterMs,
        'packet_loss_pct': packetLossPct,
        'tls_handshake_ms': tlsHandshakeMs,
        'tls_version': tlsVersion,
        'negotiated_alpn': negotiatedAlpn,
        'trace_ok': traceOk,
        'colo': colo,
        'trace_loc': traceLoc,
        'trace_ip': traceIp,
        'download_mbps': downloadMbps,
        'score': score,
        'timestamp_unix': timestampUnix,
      };

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(
        ip: (j['ip'] ?? '').toString(),
        port: (j['port'] as num?)?.toInt() ?? 443,
        country: (j['country'] ?? 'XX').toString(),
        provider: (j['provider'] ?? '').toString(),
        passed: j['passed'] as bool? ?? false,
        failReason: (j['fail_reason'] ?? '').toString(),
        minLatencyMs: (j['min_latency_ms'] as num?)?.toInt() ?? 0,
        avgLatencyMs: (j['avg_latency_ms'] as num?)?.toInt() ?? 0,
        maxLatencyMs: (j['max_latency_ms'] as num?)?.toInt() ?? 0,
        jitterMs: (j['jitter_ms'] as num?)?.toInt() ?? 0,
        packetLossPct: (j['packet_loss_pct'] as num?)?.toDouble() ?? 0.0,
        tlsHandshakeMs: (j['tls_handshake_ms'] as num?)?.toInt() ?? 0,
        tlsVersion: (j['tls_version'] ?? '').toString(),
        negotiatedAlpn: (j['negotiated_alpn'] ?? '').toString(),
        traceOk: j['trace_ok'] as bool? ?? false,
        colo: (j['colo'] ?? '').toString(),
        traceLoc: (j['trace_loc'] ?? '').toString(),
        traceIp: (j['trace_ip'] ?? '').toString(),
        downloadMbps: (j['download_mbps'] as num?)?.toDouble() ?? 0.0,
        score: (j['score'] as num?)?.toDouble() ?? 0.0,
        timestampUnix: (j['timestamp_unix'] as num?)?.toInt() ?? 0,
      );
}

class ScanProgress {
  final int total;
  final int completed;
  final int passed;
  final int failed;
  final int bestPingMs;
  final String bestIp;
  final double avgSpeedMbps;
  final int elapsedMs;
  final String phase;
  final bool isPaused;

  const ScanProgress({
    this.total = 0,
    this.completed = 0,
    this.passed = 0,
    this.failed = 0,
    this.bestPingMs = 0,
    this.bestIp = '',
    this.avgSpeedMbps = 0,
    this.elapsedMs = 0,
    this.phase = 'idle',
    this.isPaused = false,
  });

  double get fraction => total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

  factory ScanProgress.fromJson(Map<String, dynamic> j) => ScanProgress(
        total: (j['total'] as num?)?.toInt() ?? 0,
        completed: (j['completed'] as num?)?.toInt() ?? 0,
        passed: (j['passed'] as num?)?.toInt() ?? 0,
        failed: (j['failed'] as num?)?.toInt() ?? 0,
        bestPingMs: (j['best_ping_ms'] as num?)?.toInt() ?? 0,
        bestIp: (j['best_ip'] ?? '').toString(),
        avgSpeedMbps: (j['avg_speed_mbps'] as num?)?.toDouble() ?? 0.0,
        elapsedMs: (j['elapsed_ms'] as num?)?.toInt() ?? 0,
        phase: (j['phase'] ?? 'idle').toString(),
        isPaused: j['is_paused'] as bool? ?? false,
      );
}

class ScanSession {
  final String id;
  final DateTime createdAt;
  final String engineName;
  final List<String> countries;
  final int totalScanned;
  final int passedCount;
  final int bestPingMs;
  final String bestIp;
  final List<ScanResult> topResults;

  const ScanSession({
    required this.id,
    required this.createdAt,
    required this.engineName,
    required this.countries,
    required this.totalScanned,
    required this.passedCount,
    required this.bestPingMs,
    required this.bestIp,
    required this.topResults,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'engine_name': engineName,
        'countries': countries,
        'total_scanned': totalScanned,
        'passed_count': passedCount,
        'best_ping_ms': bestPingMs,
        'best_ip': bestIp,
        'top_results': topResults.map((e) => e.toJson()).toList(),
      };

  factory ScanSession.fromJson(Map<String, dynamic> j) => ScanSession(
        id: (j['id'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()) ??
            DateTime.now(),
        engineName: (j['engine_name'] ?? 'GoCore').toString(),
        countries:
            (j['countries'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        totalScanned: (j['total_scanned'] as num?)?.toInt() ?? 0,
        passedCount: (j['passed_count'] as num?)?.toInt() ?? 0,
        bestPingMs: (j['best_ping_ms'] as num?)?.toInt() ?? 0,
        bestIp: (j['best_ip'] ?? '').toString(),
        topResults: (j['top_results'] as List?)
                ?.map((e) => ScanResult.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  static String encodeList(List<ScanSession> sessions) =>
      jsonEncode(sessions.map((s) => s.toJson()).toList());

  static List<ScanSession> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ScanSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

enum ResultSortBy { score, latency, jitter, speed, country }

/// Output container: plain list, CSV table, JSON document or VLESS links.
enum ExportFormat { list, csv, json, vless }

/// Separator used between exported IPs when [ExportFormat.list] is selected.
enum ExportSeparator { newLine, comma }

/// Every toggle the export sheet exposes: separator, port and country tags.
class ExportOptions {
  final ExportSeparator separator;
  final bool includePort;
  final bool includeCountryTag;
  final bool onlyIpv6;

  const ExportOptions({
    this.separator = ExportSeparator.newLine,
    this.includePort = true,
    this.includeCountryTag = false,
    this.onlyIpv6 = false,
  });

  ExportOptions copyWith({
    ExportSeparator? separator,
    bool? includePort,
    bool? includeCountryTag,
    bool? onlyIpv6,
  }) =>
      ExportOptions(
        separator: separator ?? this.separator,
        includePort: includePort ?? this.includePort,
        includeCountryTag: includeCountryTag ?? this.includeCountryTag,
        onlyIpv6: onlyIpv6 ?? this.onlyIpv6,
      );
}

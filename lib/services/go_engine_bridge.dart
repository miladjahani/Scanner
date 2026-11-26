import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import '../models/scan_models.dart';

class EngineInfo {
  final bool goAvailable;
  final String version;

  const EngineInfo({required this.goAvailable, required this.version});
}

/// Bridges Flutter to the native Go AAR via MethodChannel/EventChannel,
/// with an automatic high-concurrency Dart `dart:io` fallback when AAR is absent.
class GoEngineBridge {
  static const _methodChannel = MethodChannel('com.edgepulse.scanner/methods');
  static const _eventChannel = EventChannel('com.edgepulse.scanner/events');

  StreamSubscription? _nativeSub;
  bool _dartCancelled = false;
  bool _dartPaused = false;
  bool _usingGo = false;

  Future<EngineInfo> getEngineInfo() async {
    try {
      final res = await _methodChannel.invokeMethod<Map>('getEngineInfo');
      if (res != null) {
        return EngineInfo(
          goAvailable: res['available'] == true,
          version: (res['version'] ?? 'Unknown').toString(),
        );
      }
    } catch (_) {
      // Non-Android or channel not registered
    }
    return const EngineInfo(goAvailable: false, version: 'DartFallback/1.0');
  }

  Future<String> startScan({
    required List<ProxyTarget> targets,
    required ScanConfig config,
    required void Function(ScanProgress) onProgress,
    required void Function(ScanResult) onResult,
    required void Function(List<ScanResult>) onComplete,
    required void Function(String) onError,
  }) async {
    final info = await getEngineInfo();
    if (info.goAvailable && config.preferGoEngine) {
      _usingGo = true;
      await _nativeSub?.cancel();
      _nativeSub = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is! Map) return;
          final type = event['type']?.toString();
          final data = event['data']?.toString() ?? '';
          try {
            if (type == 'progress') {
              onProgress(ScanProgress.fromJson(jsonDecode(data) as Map<String, dynamic>));
            } else if (type == 'result') {
              onResult(ScanResult.fromJson(jsonDecode(data) as Map<String, dynamic>));
            } else if (type == 'complete') {
              final list = (jsonDecode(data) as List)
                  .map((e) => ScanResult.fromJson(e as Map<String, dynamic>))
                  .toList();
              onComplete(list);
            } else if (type == 'error') {
              onError(data);
            }
          } catch (e) {
            onError('Event decode error: $e');
          }
        },
        onError: (Object err) => onError(err.toString()),
      );

      await _methodChannel.invokeMethod('startScan', {
        'targetsJson': jsonEncode(targets.map((t) => t.toJson()).toList()),
        'configJson': jsonEncode(config.toGoJson()),
      });
      return info.version;
    }

    // Pure Dart concurrent fallback scanner
    _usingGo = false;
    _dartCancelled = false;
    _dartPaused = false;
    unawaited(_runDartFallback(
      targets: targets,
      config: config,
      onProgress: onProgress,
      onResult: onResult,
      onComplete: onComplete,
    ));
    return 'DartFallback/1.0';
  }

  Future<void> pauseScan() async {
    if (_usingGo) {
      try {
        await _methodChannel.invokeMethod('pauseScan');
      } catch (_) {}
    } else {
      _dartPaused = true;
    }
  }

  Future<void> resumeScan() async {
    if (_usingGo) {
      try {
        await _methodChannel.invokeMethod('resumeScan');
      } catch (_) {}
    } else {
      _dartPaused = false;
    }
  }

  Future<void> stopScan() async {
    if (_usingGo) {
      try {
        await _methodChannel.invokeMethod('stopScan');
      } catch (_) {}
    } else {
      _dartCancelled = true;
      _dartPaused = false;
    }
  }

  Future<void> _runDartFallback({
    required List<ProxyTarget> targets,
    required ScanConfig config,
    required void Function(ScanProgress) onProgress,
    required void Function(ScanResult) onResult,
    required void Function(List<ScanResult>) onComplete,
  }) async {
    final sw = Stopwatch()..start();
    final total = targets.length;
    final results = <ScanResult>[];
    var completed = 0;
    var passed = 0;
    var failed = 0;
    var bestPing = 999999;
    var bestIp = '';

    var nextIndex = 0;
    final workers = min(config.concurrency.clamp(1, 128), max(1, total));

    Future<void> worker() async {
      while (!_dartCancelled) {
        while (_dartPaused && !_dartCancelled) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
        }
        if (_dartCancelled) break;
        if (nextIndex >= total) break;
        final target = targets[nextIndex++];

        final res = await _probeDart(target, config);
        results.add(res);
        completed++;
        if (res.passed) {
          passed++;
          if (res.avgLatencyMs > 0 && res.avgLatencyMs < bestPing) {
            bestPing = res.avgLatencyMs;
            bestIp = res.endpoint;
          }
        } else {
          failed++;
        }
        onResult(res);
        onProgress(ScanProgress(
          total: total,
          completed: completed,
          passed: passed,
          failed: failed,
          bestPingMs: bestPing == 999999 ? 0 : bestPing,
          bestIp: bestIp,
          elapsedMs: sw.elapsedMilliseconds,
          phase: 'scanning',
          isPaused: _dartPaused,
        ));
      }
    }

    await Future.wait(List.generate(workers, (_) => worker()));

    results.sort((a, b) {
      if (a.passed != b.passed) return a.passed ? -1 : 1;
      final sc = b.score.compareTo(a.score);
      if (sc != 0) return sc;
      return a.avgLatencyMs.compareTo(b.avgLatencyMs);
    });

    onProgress(ScanProgress(
      total: total,
      completed: completed,
      passed: passed,
      failed: failed,
      bestPingMs: bestPing == 999999 ? 0 : bestPing,
      bestIp: bestIp,
      elapsedMs: sw.elapsedMilliseconds,
      phase: _dartCancelled ? 'cancelled' : 'completed',
      isPaused: false,
    ));
    onComplete(results);
  }

  Future<ScanResult> _probeDart(ProxyTarget t, ScanConfig cfg) async {
    final samples = <int>[];
    final timeout = Duration(milliseconds: cfg.timeoutMs);

    for (var i = 0; i < cfg.probeCount; i++) {
      if (_dartCancelled) break;
      final sw = Stopwatch()..start();
      try {
        final sock = await Socket.connect(t.ip, t.port, timeout: timeout);
        samples.add(sw.elapsedMilliseconds);
        sock.destroy();
      } catch (_) {}
      if (i + 1 < cfg.probeCount && cfg.probeDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: cfg.probeDelayMs));
      }
    }

    final loss = ((cfg.probeCount - samples.length) / cfg.probeCount) * 100.0;
    if (samples.isEmpty) {
      return ScanResult(
        ip: t.ip,
        port: t.port,
        country: t.country,
        provider: t.provider,
        passed: false,
        failReason: 'tcp_timeout',
        packetLossPct: double.parse(loss.toStringAsFixed(1)),
        timestampUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    final minL = samples.reduce(min);
    final maxL = samples.reduce(max);
    final avgL = (samples.reduce((a, b) => a + b) / samples.length).round();
    var jitter = 0;
    if (samples.length > 1) {
      var diffSum = 0;
      for (var i = 1; i < samples.length; i++) {
        diffSum += (samples[i] - samples[i - 1]).abs();
      }
      jitter = (diffSum / (samples.length - 1)).round();
    }

    if (cfg.maxLatencyMs > 0 && avgL > cfg.maxLatencyMs) {
      return ScanResult(
        ip: t.ip,
        port: t.port,
        country: t.country,
        provider: t.provider,
        passed: false,
        failReason: 'latency ${avgL}ms > ${cfg.maxLatencyMs}ms',
        minLatencyMs: minL,
        avgLatencyMs: avgL,
        maxLatencyMs: maxL,
        jitterMs: jitter,
        packetLossPct: double.parse(loss.toStringAsFixed(1)),
        timestampUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    var tlsMs = 0;
    var traceOk = false;
    var colo = '';
    var traceLoc = '';
    var traceIp = '';

    if (cfg.verifyTls || cfg.verifyTrace) {
      final swTls = Stopwatch()..start();
      SecureSocket? secureSock;
      try {
        final rawSock = await Socket.connect(t.ip, t.port, timeout: timeout);
        secureSock = await SecureSocket.secure(
          rawSock,
          host: cfg.sni,
          onBadCertificate: (_) => cfg.insecureSkipCert,
        ).timeout(timeout);
        tlsMs = swTls.elapsedMilliseconds;

        if (cfg.verifyTrace) {
          secureSock.write(
            'GET ${cfg.tracePath} HTTP/1.1\r\n'
            'Host: ${cfg.traceHost}\r\n'
            'User-Agent: EdgePulseScanner/1.0\r\n'
            'Connection: close\r\n\r\n',
          );
          await secureSock.flush();
          final chunks = await secureSock
              .timeout(timeout)
              .fold<List<int>>([], (acc, b) => acc..addAll(b));
          final body = utf8.decode(chunks, allowMalformed: true);
          for (final line in body.split('\n')) {
            final idx = line.indexOf('=');
            if (idx > 0) {
              final k = line.substring(0, idx).trim();
              final v = line.substring(idx + 1).trim();
              if (k == 'colo') colo = v;
              if (k == 'loc') traceLoc = v;
              if (k == 'ip') traceIp = v;
            }
          }
          if (colo.isNotEmpty) traceOk = true;
        }
      } catch (_) {
        secureSock?.destroy();
        return ScanResult(
          ip: t.ip,
          port: t.port,
          country: t.country,
          provider: t.provider,
          passed: false,
          failReason: 'tls_handshake_failed',
          minLatencyMs: minL,
          avgLatencyMs: avgL,
          maxLatencyMs: maxL,
          jitterMs: jitter,
          packetLossPct: double.parse(loss.toStringAsFixed(1)),
          timestampUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
      } finally {
        secureSock?.destroy();
      }
    }

    if (cfg.requireCfTrace && !traceOk) {
      return ScanResult(
        ip: t.ip,
        port: t.port,
        country: t.country,
        provider: t.provider,
        passed: false,
        failReason: 'cf_trace_failed',
        minLatencyMs: minL,
        avgLatencyMs: avgL,
        maxLatencyMs: maxL,
        jitterMs: jitter,
        tlsHandshakeMs: tlsMs,
        packetLossPct: double.parse(loss.toStringAsFixed(1)),
        timestampUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    final latScore = max(0.0, 50.0 * (1.0 - avgL / 1000.0));
    final jitScore = max(0.0, 15.0 * (1.0 - jitter / 300.0));
    final lossScore = max(0.0, 15.0 * (1.0 - loss / 50.0));
    final traceScore = traceOk ? 10.0 : 0.0;
    final score = double.parse((latScore + jitScore + lossScore + traceScore).toStringAsFixed(1));

    return ScanResult(
      ip: t.ip,
      port: t.port,
      country: t.country,
      provider: t.provider,
      passed: true,
      minLatencyMs: minL,
      avgLatencyMs: avgL,
      maxLatencyMs: maxL,
      jitterMs: jitter,
      packetLossPct: double.parse(loss.toStringAsFixed(1)),
      tlsHandshakeMs: tlsMs,
      tlsVersion: 'TLS 1.3',
      traceOk: traceOk,
      colo: colo,
      traceLoc: traceLoc,
      traceIp: traceIp,
      score: score,
      timestampUnix: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Pure Dart flexible parser for custom IP:Port, CSV, and CIDR input.
  static List<ProxyTarget> parseRawTargets(
    String raw, {
    String defaultCountry = 'CUSTOM',
    List<int> defaultPorts = const [443],
    int maxPerCidr = 256,
  }) {
    final seen = <String>{};
    final out = <ProxyTarget>[];
    final ports = defaultPorts.isEmpty ? [443] : defaultPorts;

    void add(String ip, int port, String cc, String prov) {
      if (InternetAddress.tryParse(ip) == null || port <= 0 || port > 65535) {
        return;
      }
      final key = '$ip:$port';
      if (!seen.add(key)) return;
      out.add(ProxyTarget(
        ip: ip,
        port: port,
        country: cc.isEmpty ? defaultCountry : cc.toUpperCase(),
        provider: prov,
      ));
    }

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('//')) continue;

      if (line.contains(',')) {
        final parts = line.split(',');
        final ip = parts[0].trim();
        final port = parts.length >= 2 ? (int.tryParse(parts[1].trim()) ?? ports.first) : ports.first;
        final cc = parts.length >= 3 ? parts[2].trim() : defaultCountry;
        final prov = parts.length >= 4 ? parts.sublist(3).join(',').trim() : '';
        add(ip, port, cc, prov);
        continue;
      }

      if (line.contains('/')) {
        for (final ip in _expandCidr(line, maxPerCidr)) {
          for (final p in ports) {
            add(ip, p, defaultCountry, 'CIDR');
          }
        }
        continue;
      }

      if (line.contains(':')) {
        final idx = line.lastIndexOf(':');
        final host = line.substring(0, idx).replaceAll('[', '').replaceAll(']', '');
        final port = int.tryParse(line.substring(idx + 1));
        if (port != null) {
          add(host, port, defaultCountry, 'Custom');
          continue;
        }
      }

      final fields = line.split(RegExp(r'\s+'));
      if (fields.length >= 2) {
        final port = int.tryParse(fields[1]);
        if (port != null) {
          final cc = fields.length >= 3 ? fields[2] : defaultCountry;
          add(fields[0], port, cc, 'Custom');
          continue;
        }
      }

      if (InternetAddress.tryParse(fields[0]) != null) {
        for (final p in ports) {
          add(fields[0], p, defaultCountry, 'Custom');
        }
      }
    }
    return out;
  }

  static List<String> _expandCidr(String cidr, int maxCount) {
    final parts = cidr.split('/');
    if (parts.length != 2) return const [];
    final addr = InternetAddress.tryParse(parts[0].trim());
    final prefix = int.tryParse(parts[1].trim());
    if (addr == null || addr.type != InternetAddressType.IPv4 || prefix == null || prefix < 16 || prefix > 32) {
      return const [];
    }
    final b = addr.rawAddress;
    final base = (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
    final mask = prefix == 0 ? 0 : (~0 << (32 - prefix)) & 0xFFFFFFFF;
    final start = base & mask;
    final total = 1 << (32 - prefix);
    final first = total > 2 ? 1 : 0;
    final last = total > 2 ? total - 2 : total - 1;
    final usable = last - first + 1;
    final step = usable > maxCount ? max(1, usable ~/ maxCount) : 1;

    final ips = <String>[];
    for (var offset = first; offset <= last && ips.length < maxCount; offset += step) {
      final v = start + offset;
      ips.add('${(v >> 24) & 255}.${(v >> 16) & 255}.${(v >> 8) & 255}.${v & 255}');
    }
    return ips;
  }

  void dispose() {
    _nativeSub?.cancel();
  }
}

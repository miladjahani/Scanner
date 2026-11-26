import 'package:flutter/foundation.dart';
import '../data/proxy_database.dart';
import '../models/scan_models.dart';
import '../services/go_engine_bridge.dart';
import '../services/remote_sync_service.dart';
import '../services/storage_service.dart';

class ScannerController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final GoEngineBridge _bridge = GoEngineBridge();
  final RemoteSyncService _remoteSync = RemoteSyncService();

  ScanConfig config = const ScanConfig();
  EngineInfo engineInfo = const EngineInfo(goAvailable: false, version: 'Loading...');
  String locale = 'fa';

  Set<String> selectedCountries = {'DE', 'NL', 'FI', 'FR', 'TR', 'AE'};
  String customTargetsText = '';
  final Map<String, List<ProxyTarget>> syncedCountryTargets = {};

  bool isScanning = false;
  bool isSyncing = false;
  String? lastError;
  String activeEngineLabel = '';

  ScanProgress progress = const ScanProgress();
  final Map<String, ScanResult> _resultsMap = {};
  List<ScanSession> history = [];

  // Results filters & sorting
  ResultSortBy sortBy = ResultSortBy.score;
  bool onlyPassed = true;
  String filterCountry = 'ALL';
  String filterQuery = '';

  bool get isFa => locale == 'fa';

  Future<void> init() async {
    config = await _storage.loadConfig();
    selectedCountries = await _storage.loadSelectedCountries();
    customTargetsText = await _storage.loadCustomTargetsText();
    history = await _storage.loadHistory();
    locale = await _storage.loadLocale();
    engineInfo = await _bridge.getEngineInfo();
    activeEngineLabel = engineInfo.goAvailable && config.preferGoEngine
        ? engineInfo.version
        : 'DartFallback/1.0';
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    locale = locale == 'fa' ? 'en' : 'fa';
    await _storage.saveLocale(locale);
    notifyListeners();
  }

  Future<void> updateConfig(ScanConfig next) async {
    config = next;
    activeEngineLabel = engineInfo.goAvailable && config.preferGoEngine
        ? engineInfo.version
        : 'DartFallback/1.0';
    await _storage.saveConfig(config);
    notifyListeners();
  }

  Future<void> resetConfig() async {
    await updateConfig(const ScanConfig());
  }

  Future<void> toggleCountry(String code) async {
    final c = code.toUpperCase();
    if (selectedCountries.contains(c)) {
      selectedCountries.remove(c);
    } else {
      selectedCountries.add(c);
    }
    await _storage.saveSelectedCountries(selectedCountries);
    notifyListeners();
  }

  Future<void> selectCountryGroup(String group) async {
    if (group == 'ALL') {
      selectedCountries = ProxyDatabase.countries.map((e) => e.code).toSet();
    } else if (group == 'NONE') {
      selectedCountries.clear();
    } else {
      selectedCountries = ProxyDatabase.countries
          .where((e) => e.regionGroup == group)
          .map((e) => e.code)
          .toSet();
    }
    await _storage.saveSelectedCountries(selectedCountries);
    notifyListeners();
  }

  Future<void> setCustomTargetsText(String text) async {
    customTargetsText = text;
    await _storage.saveCustomTargetsText(text);
    notifyListeners();
  }

  List<ProxyTarget> buildActiveTargets() {
    final seen = <String>{};
    final out = <ProxyTarget>[];

    void addAll(Iterable<ProxyTarget> items) {
      for (final item in items) {
        if (seen.add(item.endpoint)) {
          out.add(item);
        }
      }
    }

    for (final code in selectedCountries) {
      final synced = syncedCountryTargets[code];
      if (synced != null && synced.isNotEmpty) {
        addAll(synced);
      }
      addAll(ProxyDatabase.builtInByCountry[code] ?? const []);
    }

    if (customTargetsText.trim().isNotEmpty) {
      addAll(GoEngineBridge.parseRawTargets(
        customTargetsText,
        defaultCountry: 'CUSTOM',
        defaultPorts: config.defaultPorts,
        maxPerCidr: config.maxIpsPerCidr,
      ));
    }

    return out;
  }

  Future<int> syncSelectedFromGitHub() async {
    isSyncing = true;
    lastError = null;
    notifyListeners();
    var totalFetched = 0;
    try {
      for (final cc in selectedCountries) {
        try {
          final list = await _remoteSync.fetchForCountry(cc);
          if (list.isNotEmpty) {
            syncedCountryTargets[cc] = list;
            totalFetched += list.length;
          }
        } catch (_) {}
      }
    } catch (e) {
      lastError = e.toString();
    } finally {
      isSyncing = false;
      notifyListeners();
    }
    return totalFetched;
  }

  Future<int> syncFromCustomUrl(String url) async {
    isSyncing = true;
    lastError = null;
    notifyListeners();
    try {
      final list = await _remoteSync.fetchCustomUrl(url);
      final lines = list.map((e) => '${e.ip}:${e.port}').join('\n');
      final combined = customTargetsText.trim().isEmpty
          ? lines
          : '${customTargetsText.trim()}\n$lines';
      await setCustomTargetsText(combined);
      return list.length;
    } catch (e) {
      lastError = e.toString();
      return 0;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> startScan() async {
    if (isScanning) return;
    final targets = buildActiveTargets();
    if (targets.isEmpty) {
      lastError = isFa
          ? 'حداقل یک کشور یا آی‌پی دلخواه انتخاب کنید.'
          : 'Select at least one country or add custom IPs.';
      notifyListeners();
      return;
    }

    _resultsMap.clear();
    lastError = null;
    isScanning = true;
    progress = ScanProgress(total: targets.length, phase: 'scanning');
    notifyListeners();

    try {
      activeEngineLabel = await _bridge.startScan(
        targets: targets,
        config: config,
        onProgress: (p) {
          progress = p;
          notifyListeners();
        },
        onResult: (r) {
          _resultsMap[r.endpoint] = r;
          notifyListeners();
        },
        onComplete: (finalList) async {
          for (final r in finalList) {
            _resultsMap[r.endpoint] = r;
          }
          isScanning = false;
          await _recordHistory();
          notifyListeners();
        },
        onError: (msg) {
          lastError = msg;
          isScanning = false;
          notifyListeners();
        },
      );
    } catch (e) {
      lastError = e.toString();
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> togglePause() async {
    if (!isScanning) return;
    if (progress.isPaused) {
      await _bridge.resumeScan();
      progress = ScanProgress(
        total: progress.total,
        completed: progress.completed,
        passed: progress.passed,
        failed: progress.failed,
        bestPingMs: progress.bestPingMs,
        bestIp: progress.bestIp,
        avgSpeedMbps: progress.avgSpeedMbps,
        elapsedMs: progress.elapsedMs,
        phase: progress.phase,
        isPaused: false,
      );
    } else {
      await _bridge.pauseScan();
      progress = ScanProgress(
        total: progress.total,
        completed: progress.completed,
        passed: progress.passed,
        failed: progress.failed,
        bestPingMs: progress.bestPingMs,
        bestIp: progress.bestIp,
        avgSpeedMbps: progress.avgSpeedMbps,
        elapsedMs: progress.elapsedMs,
        phase: progress.phase,
        isPaused: true,
      );
    }
    notifyListeners();
  }

  Future<void> stopScan() async {
    if (!isScanning) return;
    await _bridge.stopScan();
    isScanning = false;
    notifyListeners();
  }

  Future<void> _recordHistory() async {
    final all = allResults;
    final passed = all.where((r) => r.passed).toList();
    if (all.isEmpty) return;
    final session = ScanSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      engineName: activeEngineLabel,
      countries: selectedCountries.toList()..sort(),
      totalScanned: all.length,
      passedCount: passed.length,
      bestPingMs: passed.isNotEmpty ? passed.first.avgLatencyMs : 0,
      bestIp: passed.isNotEmpty ? passed.first.endpoint : '-',
      topResults: passed.take(50).toList(),
    );
    history = [session, ...history].take(30).toList();
    await _storage.saveHistory(history);
  }

  void loadSessionIntoResults(ScanSession session) {
    _resultsMap.clear();
    for (final r in session.topResults) {
      _resultsMap[r.endpoint] = r;
    }
    progress = ScanProgress(
      total: session.totalScanned,
      completed: session.totalScanned,
      passed: session.passedCount,
      failed: session.totalScanned - session.passedCount,
      bestPingMs: session.bestPingMs,
      bestIp: session.bestIp,
      phase: 'completed',
    );
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history = [];
    await _storage.saveHistory(history);
    notifyListeners();
  }

  List<ScanResult> get allResults {
    final list = _resultsMap.values.toList();
    list.sort(_compareResults);
    return list;
  }

  List<ScanResult> get filteredResults {
    final q = filterQuery.trim().toLowerCase();
    final list = _resultsMap.values.where((r) {
      if (onlyPassed && !r.passed) return false;
      if (filterCountry != 'ALL' && r.country != filterCountry) return false;
      if (q.isNotEmpty) {
        final hay = '${r.ip}:${r.port} ${r.country} ${r.provider} ${r.colo}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
    list.sort(_compareResults);
    return list;
  }

  int _compareResults(ScanResult a, ScanResult b) {
    if (a.passed != b.passed) return a.passed ? -1 : 1;
    switch (sortBy) {
      case ResultSortBy.score:
        final c = b.score.compareTo(a.score);
        return c != 0 ? c : a.avgLatencyMs.compareTo(b.avgLatencyMs);
      case ResultSortBy.latency:
        return a.avgLatencyMs.compareTo(b.avgLatencyMs);
      case ResultSortBy.jitter:
        return a.jitterMs.compareTo(b.jitterMs);
      case ResultSortBy.speed:
        return b.downloadMbps.compareTo(a.downloadMbps);
      case ResultSortBy.country:
        final c = a.country.compareTo(b.country);
        return c != 0 ? c : a.avgLatencyMs.compareTo(b.avgLatencyMs);
    }
  }

  void setSortBy(ResultSortBy s) {
    sortBy = s;
    notifyListeners();
  }

  void setOnlyPassed(bool v) {
    onlyPassed = v;
    notifyListeners();
  }

  void setFilterCountry(String cc) {
    filterCountry = cc;
    notifyListeners();
  }

  void setFilterQuery(String q) {
    filterQuery = q;
    notifyListeners();
  }

  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }
}

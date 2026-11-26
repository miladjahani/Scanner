import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_models.dart';

class StorageService {
  static const _keyConfig = 'edgepulse_scan_config_v1';
  static const _keySelectedCountries = 'edgepulse_selected_countries_v1';
  static const _keyCustomTargets = 'edgepulse_custom_targets_v1';
  static const _keyHistory = 'edgepulse_scan_history_v1';
  static const _keyLocale = 'edgepulse_locale_v1';

  Future<ScanConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyConfig);
    if (raw == null || raw.isEmpty) return const ScanConfig();
    try {
      return ScanConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ScanConfig();
    }
  }

  Future<void> saveConfig(ScanConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConfig, jsonEncode(config.toStorageJson()));
  }

  Future<Set<String>> loadSelectedCountries() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keySelectedCountries);
    if (list == null || list.isEmpty) return {'DE', 'NL', 'FI', 'FR', 'TR', 'AE'};
    return list.toSet();
  }

  Future<void> saveSelectedCountries(Set<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySelectedCountries, codes.toList());
  }

  Future<String> loadCustomTargetsText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomTargets) ?? '';
  }

  Future<void> saveCustomTargetsText(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomTargets, text);
  }

  Future<List<ScanSession>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyHistory);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return ScanSession.decodeList(raw);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveHistory(List<ScanSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = sessions.take(30).toList();
    await prefs.setString(_keyHistory, ScanSession.encodeList(trimmed));
  }

  Future<String> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocale) ?? 'fa';
  }

  Future<void> saveLocale(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, localeCode);
  }
}

import 'package:http/http.dart' as http;
import '../models/scan_models.dart';
import 'go_engine_bridge.dart';

class RemoteSyncService {
  static const String globalListUrl =
      'https://raw.githubusercontent.com/FoolVPN-ID/Nautica/main/proxyList.txt';

  static String countryListUrl(String countryCode) =>
      'https://raw.githubusercontent.com/NiREvil/vless/main/sub/country_proxies/${countryCode.toUpperCase()}.txt';

  /// Fetches the latest country-specific ProxyIP list.
  Future<List<ProxyTarget>> fetchForCountry(String countryCode) async {
    final cc = countryCode.toUpperCase();
    final uri = Uri.parse(countryListUrl(cc));
    final resp = await http.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} while fetching $cc list');
    }
    return GoEngineBridge.parseRawTargets(
      resp.body,
      defaultCountry: cc,
      defaultPorts: const [443],
    );
  }

  /// Fetches the full multi-country ProxyIP list.
  Future<List<ProxyTarget>> fetchGlobalList() async {
    final resp = await http
        .get(Uri.parse(globalListUrl))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} while fetching the global list');
    }
    return GoEngineBridge.parseRawTargets(
      resp.body,
      defaultCountry: 'XX',
      defaultPorts: const [443],
    );
  }

  /// Fetches any custom raw text/CSV URL provided by the user.
  Future<List<ProxyTarget>> fetchCustomUrl(String url, {String defaultCountry = 'CUSTOM'}) async {
    final resp = await http
        .get(Uri.parse(url.trim()))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    return GoEngineBridge.parseRawTargets(
      resp.body,
      defaultCountry: defaultCountry,
      defaultPorts: const [443],
    );
  }
}

import '../models/scan_models.dart';

class CountryMeta {
  final String code;
  final String nameFa;
  final String nameEn;
  final String flag;
  final String regionGroup;
  final String placementHint;

  const CountryMeta({
    required this.code,
    required this.nameFa,
    required this.nameEn,
    required this.flag,
    required this.regionGroup,
    required this.placementHint,
  });
}

class DynamicProxyDomain {
  final String domain;
  final String country;
  final String note;

  const DynamicProxyDomain({
    required this.domain,
    required this.country,
    required this.note,
  });
}

/// Built-in verified ProxyIP dataset extracted from NiREvil/vless and FoolVPN-ID/Nautica.
class ProxyDatabase {
  static const List<CountryMeta> countries = [
    CountryMeta(code: 'DE', nameFa: 'آلمان', nameEn: 'Germany', flag: '🇩🇪', regionGroup: 'EU', placementHint: 'aws:eu-central-1'),
    CountryMeta(code: 'NL', nameFa: 'هلند', nameEn: 'Netherlands', flag: '🇳🇱', regionGroup: 'EU', placementHint: 'azure:westeurope'),
    CountryMeta(code: 'FI', nameFa: 'فنلاند', nameEn: 'Finland', flag: '🇫🇮', regionGroup: 'EU', placementHint: 'gcp:europe-north1'),
    CountryMeta(code: 'FR', nameFa: 'فرانسه', nameEn: 'France', flag: '🇫🇷', regionGroup: 'EU', placementHint: 'aws:eu-west-3'),
    CountryMeta(code: 'GB', nameFa: 'بریتانیا', nameEn: 'United Kingdom', flag: '🇬🇧', regionGroup: 'EU', placementHint: 'aws:eu-west-2'),
    CountryMeta(code: 'SE', nameFa: 'سوئد', nameEn: 'Sweden', flag: '🇸🇪', regionGroup: 'EU', placementHint: 'aws:eu-north-1'),
    CountryMeta(code: 'CH', nameFa: 'سوئیس', nameEn: 'Switzerland', flag: '🇨🇭', regionGroup: 'EU', placementHint: 'aws:eu-central-2'),
    CountryMeta(code: 'ES', nameFa: 'اسپانیا', nameEn: 'Spain', flag: '🇪🇸', regionGroup: 'EU', placementHint: 'aws:eu-south-2'),
    CountryMeta(code: 'PL', nameFa: 'لهستان', nameEn: 'Poland', flag: '🇵🇱', regionGroup: 'EU', placementHint: 'gcp:europe-central2'),
    CountryMeta(code: 'TR', nameFa: 'ترکیه', nameEn: 'Turkey', flag: '🇹🇷', regionGroup: 'ME', placementHint: 'aws:eu-central-1'),
    CountryMeta(code: 'AE', nameFa: 'امارات', nameEn: 'UAE', flag: '🇦🇪', regionGroup: 'ME', placementHint: 'aws:me-central-1'),
    CountryMeta(code: 'US', nameFa: 'آمریکا', nameEn: 'United States', flag: '🇺🇸', regionGroup: 'AM', placementHint: 'aws:us-east-1'),
    CountryMeta(code: 'CA', nameFa: 'کانادا', nameEn: 'Canada', flag: '🇨🇦', regionGroup: 'AM', placementHint: 'aws:ca-central-1'),
    CountryMeta(code: 'SG', nameFa: 'سنگاپور', nameEn: 'Singapore', flag: '🇸🇬', regionGroup: 'AS', placementHint: 'azure:southeastasia'),
    CountryMeta(code: 'JP', nameFa: 'ژاپن', nameEn: 'Japan', flag: '🇯🇵', regionGroup: 'AS', placementHint: 'aws:ap-northeast-1'),
    CountryMeta(code: 'AU', nameFa: 'استرالیا', nameEn: 'Australia', flag: '🇦🇺', regionGroup: 'AS', placementHint: 'aws:ap-southeast-2'),
    CountryMeta(code: 'BR', nameFa: 'برزیل', nameEn: 'Brazil', flag: '🇧🇷', regionGroup: 'AM', placementHint: 'aws:sa-east-1'),
    CountryMeta(code: 'IE', nameFa: 'ایرلند', nameEn: 'Ireland', flag: '🇮🇪', regionGroup: 'EU', placementHint: 'aws:eu-west-1'),
    CountryMeta(code: 'IN', nameFa: 'هند', nameEn: 'India', flag: '🇮🇳', regionGroup: 'AS', placementHint: 'aws:ap-south-1'),
    CountryMeta(code: 'LV', nameFa: 'لتونی', nameEn: 'Latvia', flag: '🇱🇻', regionGroup: 'EU', placementHint: 'aws:eu-north-1'),
  ];

  static const List<String> placementPresets = [
    'aws:eu-central-1',
    'azure:westeurope',
    'gcp:europe-west1',
    'aws:eu-west-2',
    'aws:eu-west-3',
    'aws:eu-north-1',
    'aws:me-central-1',
    'aws:us-east-1',
    'gcp:us-east4',
    'aws:us-west-2',
    'azure:eastus',
    'azure:southeastasia',
    'gcp:asia-east1',
    'aws:ap-northeast-1',
  ];

  static const List<DynamicProxyDomain> dynamicDomains = [
    DynamicProxyDomain(domain: 'ProxyIP.DE.CMLiussss.net', country: 'DE', note: 'Germany Pool'),
    DynamicProxyDomain(domain: 'ProxyIP.US.CMLiussss.net', country: 'US', note: 'USA Pool'),
    DynamicProxyDomain(domain: 'ProxyIP.SG.CMLiussss.net', country: 'SG', note: 'Singapore Pool'),
    DynamicProxyDomain(domain: 'ProxyIP.JP.CMLiussss.net', country: 'JP', note: 'Japan Pool'),
    DynamicProxyDomain(domain: 'ProxyIP.KR.CMLiussss.net', country: 'KR', note: 'South Korea Pool'),
    DynamicProxyDomain(domain: 'ProxyIP.HK.CMLiussss.net', country: 'HK', note: 'Hong Kong Pool'),
    DynamicProxyDomain(domain: 'tr.diam4.ggff.net', country: 'TR', note: 'Istanbul Pool'),
    DynamicProxyDomain(domain: 'di.nscl.ir', country: 'DE/US', note: 'Multi-Cloud Pool'),
    DynamicProxyDomain(domain: 'bpb.yousef.isegaro.com', country: 'GLOBAL', note: 'BPB Panel Pool'),
    DynamicProxyDomain(domain: 'proxyip.cmliussss.net', country: 'GLOBAL', note: 'Worldwide Pool'),
    DynamicProxyDomain(domain: 'proxy.zjcloud.us.ci', country: 'GLOBAL', note: 'Cloudflare Proxy Pool'),
    DynamicProxyDomain(domain: 'cdn.xn--b6gac.eu.org', country: 'GLOBAL', note: 'Public CDN Pool'),
  ];

  static CountryMeta metaFor(String code) {
    return countries.firstWhere(
      (c) => c.code == code.toUpperCase(),
      orElse: () => CountryMeta(
        code: code.toUpperCase(),
        nameFa: code.toUpperCase(),
        nameEn: code.toUpperCase(),
        flag: '🌐',
        regionGroup: 'OTHER',
        placementHint: 'aws:eu-central-1',
      ),
    );
  }

  static final Map<String, List<ProxyTarget>> builtInByCountry = {
    'DE': [
      const ProxyTarget(ip: '116.203.58.165', port: 443, country: 'DE', provider: 'Hetzner Online'),
      const ProxyTarget(ip: '142.132.178.99', port: 443, country: 'DE', provider: 'Hetzner Online'),
      const ProxyTarget(ip: '18.184.55.249', port: 443, country: 'DE', provider: 'AWS Frankfurt'),
      const ProxyTarget(ip: '18.184.27.249', port: 443, country: 'DE', provider: 'AWS Frankfurt'),
      const ProxyTarget(ip: '18.197.218.69', port: 443, country: 'DE', provider: 'AWS Frankfurt'),
      const ProxyTarget(ip: '18.156.209.101', port: 443, country: 'DE', provider: 'Amazon Data Services'),
      const ProxyTarget(ip: '18.185.254.189', port: 443, country: 'DE', provider: 'Amazon Data Services'),
      const ProxyTarget(ip: '3.68.62.122', port: 443, country: 'DE', provider: 'AWS Frankfurt'),
      const ProxyTarget(ip: '3.127.55.133', port: 443, country: 'DE', provider: 'Amazon Data Services'),
      const ProxyTarget(ip: '3.68.31.54', port: 443, country: 'DE', provider: 'Amazon Data Services'),
      const ProxyTarget(ip: '3.66.115.225', port: 443, country: 'DE', provider: 'AWS Frankfurt'),
      const ProxyTarget(ip: '3.69.0.8', port: 443, country: 'DE', provider: 'Amazon Data Services'),
      const ProxyTarget(ip: '35.157.240.237', port: 443, country: 'DE', provider: 'AWS Frankfurt'),
      const ProxyTarget(ip: '162.19.247.245', port: 443, country: 'DE', provider: 'OVH GmbH'),
      const ProxyTarget(ip: '51.195.119.195', port: 8443, country: 'DE', provider: 'OVH GmbH'),
      const ProxyTarget(ip: '193.124.92.170', port: 443, country: 'DE', provider: 'GLB Bulut'),
      const ProxyTarget(ip: '37.1.195.124', port: 443, country: 'DE', provider: 'IROKO Networks'),
      const ProxyTarget(ip: '5.61.39.183', port: 443, country: 'DE', provider: 'IROKO Networks'),
      const ProxyTarget(ip: '80.76.32.165', port: 443, country: 'DE', provider: 'FIRST SERVER'),
      const ProxyTarget(ip: '91.149.223.242', port: 443, country: 'DE', provider: 'Baxet Group'),
      const ProxyTarget(ip: '176.124.204.12', port: 443, country: 'DE', provider: 'AEZA GROUP'),
      const ProxyTarget(ip: '77.221.157.32', port: 443, country: 'DE', provider: 'AEZA GROUP'),
      const ProxyTarget(ip: '194.28.225.2', port: 443, country: 'DE', provider: 'nuxtcloud'),
      const ProxyTarget(ip: '194.58.33.218', port: 443, country: 'DE', provider: 'nuxtcloud'),
      const ProxyTarget(ip: '87.251.87.36', port: 443, country: 'DE', provider: 'nuxtcloud'),
      const ProxyTarget(ip: '217.110.20.141', port: 443, country: 'DE', provider: 'Colt DC'),
      const ProxyTarget(ip: '89.168.68.57', port: 8443, country: 'DE', provider: 'Oracle'),
      const ProxyTarget(ip: '49.12.243.75', port: 8443, country: 'DE', provider: 'Hetzner Online'),
      const ProxyTarget(ip: '104.248.132.134', port: 443, country: 'DE', provider: 'DigitalOcean FRA'),
      const ProxyTarget(ip: '134.122.69.33', port: 443, country: 'DE', provider: 'DigitalOcean FRA'),
      const ProxyTarget(ip: '138.68.64.213', port: 443, country: 'DE', provider: 'DigitalOcean FRA'),
      const ProxyTarget(ip: '188.245.59.37', port: 443, country: 'DE', provider: 'Hetzner DE'),
      const ProxyTarget(ip: '49.13.228.85', port: 443, country: 'DE', provider: 'Hetzner DE'),
      const ProxyTarget(ip: '5.75.182.89', port: 443, country: 'DE', provider: 'Hetzner DE'),
    ],
    'NL': [
      const ProxyTarget(ip: '37.48.90.120', port: 443, country: 'NL', provider: 'LeaseWeb NL'),
      const ProxyTarget(ip: '146.190.236.144', port: 443, country: 'NL', provider: 'DigitalOcean AMS'),
      const ProxyTarget(ip: '164.92.219.230', port: 2053, country: 'NL', provider: 'DigitalOcean AMS'),
      const ProxyTarget(ip: '23.108.217.103', port: 443, country: 'NL', provider: 'Servers.com'),
      const ProxyTarget(ip: '46.17.102.93', port: 443, country: 'NL', provider: 'HOSTKEY B.V.'),
      const ProxyTarget(ip: '146.0.73.202', port: 443, country: 'NL', provider: 'HOSTKEY B.V.'),
      const ProxyTarget(ip: '193.109.69.78', port: 8443, country: 'NL', provider: 'HOSTKEY B.V.'),
      const ProxyTarget(ip: '194.58.39.80', port: 443, country: 'NL', provider: 'Baxet Group'),
      const ProxyTarget(ip: '93.113.171.31', port: 443, country: 'NL', provider: 'Baxet Group'),
      const ProxyTarget(ip: '85.192.60.129', port: 443, country: 'NL', provider: 'AEZA GROUP'),
      const ProxyTarget(ip: '91.184.242.46', port: 443, country: 'NL', provider: 'AEZA GROUP'),
      const ProxyTarget(ip: '45.155.249.66', port: 443, country: 'NL', provider: 'servinga GmbH'),
      const ProxyTarget(ip: '94.241.174.229', port: 443, country: 'NL', provider: 'Timeweb'),
      const ProxyTarget(ip: '86.107.197.161', port: 443, country: 'NL', provider: 'MVPS LTD'),
      const ProxyTarget(ip: '193.160.96.232', port: 443, country: 'NL', provider: 'FiberXpress BV'),
      const ProxyTarget(ip: '213.183.51.71', port: 443, country: 'NL', provider: 'Melbicom'),
      const ProxyTarget(ip: '185.243.112.197', port: 443, country: 'NL', provider: 'CrownCloud'),
      const ProxyTarget(ip: '45.133.118.153', port: 443, country: 'NL', provider: 'Hizakura B.V.'),
    ],
    'FI': [
      const ProxyTarget(ip: '95.216.206.37', port: 443, country: 'FI', provider: 'Hetzner FI'),
      const ProxyTarget(ip: '65.108.245.196', port: 443, country: 'FI', provider: 'Hetzner FI'),
      const ProxyTarget(ip: '95.216.140.177', port: 443, country: 'FI', provider: 'Hetzner FI'),
      const ProxyTarget(ip: '135.181.250.100', port: 8443, country: 'FI', provider: 'Hetzner FI'),
      const ProxyTarget(ip: '65.108.149.250', port: 8443, country: 'FI', provider: 'Hetzner FI'),
      const ProxyTarget(ip: '65.109.161.254', port: 8443, country: 'FI', provider: 'Hetzner FI'),
      const ProxyTarget(ip: '65.109.12.58', port: 8443, country: 'FI', provider: 'Hetzner FI'),
      const ProxyTarget(ip: '95.216.148.189', port: 8443, country: 'FI', provider: 'Hetzner FI'),
      const ProxyTarget(ip: '212.237.219.99', port: 443, country: 'FI', provider: 'HOSTKEY'),
      const ProxyTarget(ip: '185.188.181.14', port: 443, country: 'FI', provider: 'PSERVERS'),
      const ProxyTarget(ip: '185.112.82.28', port: 443, country: 'FI', provider: 'Creanova'),
      const ProxyTarget(ip: '109.120.185.29', port: 443, country: 'FI', provider: 'NetCrafters'),
    ],
    'FR': [
      const ProxyTarget(ip: '37.187.98.185', port: 443, country: 'FR', provider: 'OVH SAS'),
      const ProxyTarget(ip: '51.38.44.17', port: 443, country: 'FR', provider: 'OVH SAS'),
      const ProxyTarget(ip: '5.196.27.246', port: 8443, country: 'FR', provider: 'OVH SAS'),
      const ProxyTarget(ip: '51.159.6.227', port: 8443, country: 'FR', provider: 'Scaleway'),
      const ProxyTarget(ip: '45.63.114.83', port: 443, country: 'FR', provider: 'Vultr FR'),
      const ProxyTarget(ip: '88.218.76.170', port: 443, country: 'FR', provider: 'RackNerd FR'),
      const ProxyTarget(ip: '152.228.191.232', port: 443, country: 'FR', provider: 'OVH FR'),
      const ProxyTarget(ip: '104.238.191.179', port: 443, country: 'FR', provider: 'NiREvil FR'),
      const ProxyTarget(ip: '134.209.19.200', port: 443, country: 'FR', provider: 'NiREvil FR'),
      const ProxyTarget(ip: '146.70.32.13', port: 443, country: 'FR', provider: 'M247 FR'),
      const ProxyTarget(ip: '164.132.101.80', port: 443, country: 'FR', provider: 'OVH FR'),
      const ProxyTarget(ip: '54.37.39.40', port: 443, country: 'FR', provider: 'OVH FR'),
      const ProxyTarget(ip: '51.91.40.26', port: 443, country: 'FR', provider: 'OVH FR'),
    ],
    'GB': [
      const ProxyTarget(ip: '212.113.116.93', port: 443, country: 'GB', provider: 'AEZA GROUP'),
      const ProxyTarget(ip: '79.137.248.111', port: 443, country: 'GB', provider: 'AEZA GROUP'),
      const ProxyTarget(ip: '77.221.136.148', port: 443, country: 'GB', provider: 'AEZA GROUP'),
      const ProxyTarget(ip: '77.221.143.39', port: 443, country: 'GB', provider: 'AEZA GROUP'),
      const ProxyTarget(ip: '185.66.164.51', port: 443, country: 'GB', provider: 'Perfecto UK'),
      const ProxyTarget(ip: '213.1.145.50', port: 443, country: 'GB', provider: 'BT UK'),
      const ProxyTarget(ip: '103.13.208.242', port: 443, country: 'GB', provider: 'OMC UK'),
      const ProxyTarget(ip: '109.169.76.23', port: 443, country: 'GB', provider: 'Iomart UK'),
      const ProxyTarget(ip: '104.128.190.209', port: 443, country: 'GB', provider: '365 Group'),
      const ProxyTarget(ip: '91.149.238.88', port: 443, country: 'GB', provider: 'Baxet Group'),
    ],
    'SE': [
      const ProxyTarget(ip: '45.82.80.96', port: 443, country: 'SE', provider: 'Internetport SE'),
      const ProxyTarget(ip: '158.179.206.143', port: 443, country: 'SE', provider: 'Oracle SE'),
      const ProxyTarget(ip: '129.151.198.3', port: 8443, country: 'SE', provider: 'Oracle SE'),
      const ProxyTarget(ip: '147.45.76.69', port: 443, country: 'SE', provider: 'AEZA GROUP'),
      const ProxyTarget(ip: '46.226.161.129', port: 2053, country: 'SE', provider: 'AEZA GROUP'),
    ],
    'CH': [
      const ProxyTarget(ip: '91.90.193.24', port: 443, country: 'CH', provider: 'Friendhosting'),
      const ProxyTarget(ip: '176.10.125.114', port: 443, country: 'CH', provider: 'Datasource AG'),
      const ProxyTarget(ip: '91.192.102.55', port: 443, country: 'CH', provider: 'Datasource AG'),
      const ProxyTarget(ip: '185.195.69.200', port: 8443, country: 'CH', provider: 'Datasource AG'),
      const ProxyTarget(ip: '91.245.225.69', port: 443, country: 'CH', provider: 'GLB Bulut'),
      const ProxyTarget(ip: '38.180.85.203', port: 443, country: 'CH', provider: '3NT Solutions'),
    ],
    'ES': [
      const ProxyTarget(ip: '34.175.202.195', port: 443, country: 'ES', provider: 'Google LLC'),
      const ProxyTarget(ip: '212.227.90.142', port: 443, country: 'ES', provider: 'IONOS SE'),
      const ProxyTarget(ip: '212.227.144.37', port: 8443, country: 'ES', provider: 'IONOS SE'),
      const ProxyTarget(ip: '45.86.229.28', port: 443, country: 'ES', provider: 'BlueVPS'),
      const ProxyTarget(ip: '93.93.119.91', port: 443, country: 'ES', provider: 'Arsys ES'),
    ],
    'PL': [
      const ProxyTarget(ip: '188.116.40.37', port: 443, country: 'PL', provider: 'Artnet PL'),
      const ProxyTarget(ip: '91.149.253.249', port: 443, country: 'PL', provider: 'BG-NETWORK'),
      const ProxyTarget(ip: '37.252.6.119', port: 443, country: 'PL', provider: 'IROKO Networks'),
      const ProxyTarget(ip: '146.59.19.208', port: 8443, country: 'PL', provider: 'OVH PL'),
      const ProxyTarget(ip: '145.239.88.255', port: 8443, country: 'PL', provider: 'OVH WAW'),
      const ProxyTarget(ip: '80.211.249.68', port: 8443, country: 'PL', provider: 'Aruba Cloud PL'),
    ],
    'TR': [
      const ProxyTarget(ip: '185.234.66.91', port: 443, country: 'TR', provider: 'WorkTitans'),
      const ProxyTarget(ip: '94.131.123.74', port: 443, country: 'TR', provider: 'WorkTitans'),
      const ProxyTarget(ip: '45.89.52.247', port: 443, country: 'TR', provider: 'WorkTitans'),
      const ProxyTarget(ip: '130.94.1.177', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '141.98.118.80', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '155.103.71.111', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '178.157.15.73', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '185.200.36.36', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '194.36.85.113', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '213.155.119.28', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '45.136.5.132', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '5.180.32.101', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '77.83.245.48', port: 443, country: 'TR', provider: 'NiREvil TR'),
      const ProxyTarget(ip: '130.185.122.48', port: 443, country: 'TR', provider: 'NiREvil TR'),
    ],
    'AE': [
      const ProxyTarget(ip: '45.86.228.104', port: 443, country: 'AE', provider: 'BlueVPS AE'),
      const ProxyTarget(ip: '176.97.66.175', port: 443, country: 'AE', provider: '3nt Solutions'),
      const ProxyTarget(ip: '146.70.37.253', port: 443, country: 'AE', provider: 'M247 Dubai'),
      const ProxyTarget(ip: '156.154.245.83', port: 443, country: 'AE', provider: 'Arbor Cloud'),
      const ProxyTarget(ip: '156.154.245.84', port: 443, country: 'AE', provider: 'NiREvil AE'),
      const ProxyTarget(ip: '172.86.76.47', port: 443, country: 'AE', provider: 'NiREvil AE'),
      const ProxyTarget(ip: '188.208.110.30', port: 443, country: 'AE', provider: 'NiREvil AE'),
      const ProxyTarget(ip: '20.174.15.226', port: 443, country: 'AE', provider: 'Azure UAE'),
      const ProxyTarget(ip: '3.29.240.49', port: 443, country: 'AE', provider: 'AWS UAE'),
      const ProxyTarget(ip: '84.235.255.82', port: 443, country: 'AE', provider: 'NiREvil AE'),
      const ProxyTarget(ip: '91.132.93.153', port: 443, country: 'AE', provider: 'NiREvil AE'),
    ],
    'US': [
      const ProxyTarget(ip: '147.75.230.33', port: 443, country: 'US', provider: 'Aryaka Networks'),
      const ProxyTarget(ip: '147.75.230.207', port: 443, country: 'US', provider: 'Aryaka Networks'),
      const ProxyTarget(ip: '18.216.55.100', port: 443, country: 'US', provider: 'Amazon US'),
      const ProxyTarget(ip: '18.216.207.41', port: 443, country: 'US', provider: 'AWS US'),
      const ProxyTarget(ip: '18.222.50.18', port: 443, country: 'US', provider: 'AWS US'),
      const ProxyTarget(ip: '147.135.10.209', port: 443, country: 'US', provider: 'OVH US'),
      const ProxyTarget(ip: '129.146.46.164', port: 443, country: 'US', provider: 'Oracle US'),
      const ProxyTarget(ip: '129.159.84.71', port: 443, country: 'US', provider: 'Oracle US'),
      const ProxyTarget(ip: '141.148.187.195', port: 443, country: 'US', provider: 'Oracle US'),
      const ProxyTarget(ip: '192.9.250.241', port: 443, country: 'US', provider: 'Oracle US'),
      const ProxyTarget(ip: '47.251.95.178', port: 443, country: 'US', provider: 'Alibaba US'),
      const ProxyTarget(ip: '23.95.113.61', port: 443, country: 'US', provider: 'RackNerd US'),
      const ProxyTarget(ip: '107.173.87.103', port: 443, country: 'US', provider: 'RackNerd US'),
      const ProxyTarget(ip: '162.219.120.218', port: 443, country: 'US', provider: 'Cluster Logic'),
      const ProxyTarget(ip: '72.13.122.137', port: 443, country: 'US', provider: 'Total Uptime'),
      const ProxyTarget(ip: '104.248.208.69', port: 443, country: 'US', provider: 'DigitalOcean US'),
      const ProxyTarget(ip: '157.230.140.153', port: 443, country: 'US', provider: 'DigitalOcean US'),
      const ProxyTarget(ip: '20.106.211.232', port: 443, country: 'US', provider: 'Azure US'),
    ],
    'CA': [
      const ProxyTarget(ip: '172.98.207.58', port: 443, country: 'CA', provider: 'CentriLogic CA'),
    ],
    'SG': [
      const ProxyTarget(ip: '143.42.66.91', port: 443, country: 'SG', provider: 'M1 Ltd'),
      const ProxyTarget(ip: '164.52.2.100', port: 443, country: 'SG', provider: 'UCUL-SG'),
      const ProxyTarget(ip: '43.156.181.203', port: 443, country: 'SG', provider: 'Collyer Quay'),
      const ProxyTarget(ip: '13.212.102.10', port: 443, country: 'SG', provider: 'AWS Singapore'),
      const ProxyTarget(ip: '13.212.207.124', port: 443, country: 'SG', provider: 'AWS Singapore'),
      const ProxyTarget(ip: '104.248.152.221', port: 443, country: 'SG', provider: 'DigitalOcean SG'),
      const ProxyTarget(ip: '128.199.128.117', port: 443, country: 'SG', provider: 'DigitalOcean SG'),
      const ProxyTarget(ip: '139.162.33.165', port: 443, country: 'SG', provider: 'Linode SG'),
      const ProxyTarget(ip: '152.42.163.208', port: 443, country: 'SG', provider: 'NiREvil SG'),
      const ProxyTarget(ip: '47.82.155.79', port: 443, country: 'SG', provider: 'Alibaba SG'),
    ],
    'JP': [
      const ProxyTarget(ip: '45.76.198.248', port: 443, country: 'JP', provider: 'Vultr JP'),
      const ProxyTarget(ip: '149.28.21.106', port: 443, country: 'JP', provider: 'Vultr JP'),
      const ProxyTarget(ip: '168.138.46.67', port: 443, country: 'JP', provider: 'Oracle JP'),
      const ProxyTarget(ip: '64.110.104.30', port: 443, country: 'JP', provider: 'Oracle JP'),
      const ProxyTarget(ip: '103.75.118.144', port: 2053, country: 'JP', provider: 'Oneprovider JP'),
    ],
    'AU': [
      const ProxyTarget(ip: '125.7.24.251', port: 443, country: 'AU', provider: 'Macquarie AU'),
      const ProxyTarget(ip: '45.77.236.204', port: 443, country: 'AU', provider: 'Vultr AU'),
    ],
    'BR': [
      const ProxyTarget(ip: '38.180.78.255', port: 443, country: 'BR', provider: '3NT Solutions'),
      const ProxyTarget(ip: '38.180.79.9', port: 443, country: 'BR', provider: '3NT Solutions'),
      const ProxyTarget(ip: '146.235.59.153', port: 8443, country: 'BR', provider: 'Oracle BR'),
    ],
    'IE': [
      const ProxyTarget(ip: '54.229.164.147', port: 2053, country: 'IE', provider: 'AWS Ireland'),
      const ProxyTarget(ip: '63.32.194.15', port: 8443, country: 'IE', provider: 'AWS Ireland'),
    ],
    'IN': [
      const ProxyTarget(ip: '20.235.105.146', port: 443, country: 'IN', provider: 'Microsoft Azure'),
      const ProxyTarget(ip: '216.10.243.159', port: 443, country: 'IN', provider: 'PDR Solutions'),
    ],
    'LV': [
      const ProxyTarget(ip: '46.8.237.3', port: 443, country: 'LV', provider: 'CGI Global'),
      const ProxyTarget(ip: '192.144.39.33', port: 443, country: 'LV', provider: 'SIA Serverum'),
      const ProxyTarget(ip: '216.173.71.171', port: 443, country: 'LV', provider: 'SIA VEESP'),
      const ProxyTarget(ip: '91.197.3.157', port: 443, country: 'LV', provider: 'SIA VEESP'),
    ],
  };

  static List<ProxyTarget> targetsForCountries(Set<String> selectedCodes) {
    final result = <ProxyTarget>[];
    for (final code in selectedCodes) {
      final list = builtInByCountry[code.toUpperCase()];
      if (list != null) {
        result.addAll(list);
      }
    }
    return result;
  }
}

import 'package:flutter/material.dart';
import 'widgets/mili_logo.dart';
import 'screens/countries_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/results_screen.dart';
import 'screens/settings_screen.dart';
import 'state/scanner_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiliScannerApp());
}

class MiliScannerApp extends StatefulWidget {
  const MiliScannerApp({super.key});

  @override
  State<MiliScannerApp> createState() => _MiliScannerAppState();
}

class _MiliScannerAppState extends State<MiliScannerApp> {
  final ScannerController _controller = ScannerController();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isFa = _controller.isFa;
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E676),
          brightness: Brightness.dark,
          surface: const Color(0xFF0B0F14),
        );

        return MaterialApp(
          title: 'miliscanner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: scheme,
            scaffoldBackgroundColor: const Color(0xFF070A0E),
            cardTheme: CardThemeData(
              color: const Color(0xFF0E141C),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF16202B),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF141C27),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: isFa ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF070A0E),
              elevation: 0,
              titleSpacing: 14,
              title: Row(
                children: [
                  const MiliLogo(size: 34),
                  const SizedBox(width: 9),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'miliscanner',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _controller.activeEngineLabel.isEmpty
                            ? 'Go + Dart Core'
                            : _controller.activeEngineLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: _controller.engineInfo.goAvailable
                              ? const Color(0xFF00E676)
                              : Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _controller.toggleLocale,
                  child: Text(
                    isFa ? 'EN' : 'فارسی',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            body: IndexedStack(
              index: _tabIndex,
              children: [
                DashboardScreen(
                  controller: _controller,
                  onOpenResults: () => setState(() => _tabIndex = 2),
                ),
                CountriesScreen(controller: _controller),
                ResultsScreen(controller: _controller),
                SettingsScreen(controller: _controller),
                HistoryScreen(
                  controller: _controller,
                  onOpenResults: () => setState(() => _tabIndex = 2),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              backgroundColor: const Color(0xFF0B0F14),
              indicatorColor: const Color(0xFF00E676).withValues(alpha: 0.18),
              selectedIndex: _tabIndex,
              onDestinationSelected: (i) => setState(() => _tabIndex = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.radar_outlined),
                  selectedIcon: const Icon(Icons.radar, color: Color(0xFF00E676)),
                  label: isFa ? 'اسکنر' : 'Scanner',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.public_outlined),
                  selectedIcon: const Icon(Icons.public, color: Color(0xFF00E676)),
                  label: isFa ? 'کشورها' : 'Countries',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bolt_outlined),
                  selectedIcon: const Icon(Icons.bolt, color: Color(0xFF00E676)),
                  label: isFa ? 'نتایج' : 'Results',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.tune_outlined),
                  selectedIcon: const Icon(Icons.tune, color: Color(0xFF00E676)),
                  label: isFa ? 'تنظیمات' : 'Settings',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_outlined),
                  selectedIcon: const Icon(Icons.history, color: Color(0xFF00E676)),
                  label: isFa ? 'تاریخچه' : 'History',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

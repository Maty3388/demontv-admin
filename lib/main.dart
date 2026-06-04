import 'package:flutter/material.dart';
import 'services/api.dart';
import 'package:flutter/services.dart';
import 'theme/theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/monitor_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/series_screen.dart';
import 'screens/channels_screen.dart';
import 'screens/spin_screen.dart';
import 'screens/version_screen.dart';
import 'screens/resellers_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminApi.loadToken();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const DemonTvAdminApp());
}

class DemonTvAdminApp extends StatelessWidget {
  const DemonTvAdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DemonTv Plus Admin',
    debugShowCheckedModeBanner: false,
    theme: AdminTheme.dark,
    initialRoute: AdminApi.token != null ? '/dashboard' : '/login',
    routes: {
      '/login':     (_) => const AdminLoginScreen(),
      '/dashboard': (_) => const MainNavScreen(),
    },
  );
}

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override State<MainNavScreen> createState() => _NavState();
}

class _NavState extends State<MainNavScreen> {
  int _idx = 0;

  final _screens = const [
    DashboardScreen(),
    MonitorScreen(),
    ChannelsScreen(),
    MoviesScreen(),
    SeriesAdminScreen(),
    LogsScreen(),
    VersionScreen(),
    ResellersScreen(),
    SpinScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    body: IndexedStack(index: _idx, children: _screens),
    bottomNavigationBar: _buildNav(),
  );

  Widget _buildNav() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      border: Border(top: BorderSide(color: AdminTheme.border, width: 0.5)),
    ),
    child: SafeArea(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _NavBtn(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Panel', index: 0, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.monitor_outlined, activeIcon: Icons.monitor, label: 'Monitor', index: 1, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv, label: 'Canales', index: 2, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.movie_outlined, activeIcon: Icons.movie, label: 'Películas', index: 3, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.tv_outlined, activeIcon: Icons.tv, label: 'Series', index: 4, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Logs', index: 5, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.system_update_outlined, activeIcon: Icons.system_update, label: 'Update', index: 6, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.store_outlined, activeIcon: Icons.store, label: 'Resellers', index: 7, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.casino_outlined, activeIcon: Icons.casino, label: 'Ruleta', index: 8, selected: _idx, onTap: (i) => setState(() => _idx = i)),
      ]),
    )),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, selected;
  final void Function(int) onTap;
  const _NavBtn({required this.icon, required this.activeIcon, required this.label, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isSelected ? activeIcon : icon, size: 22,
            color: isSelected ? AdminTheme.cyan : const Color(0xFF5C5C5C)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: isSelected ? AdminTheme.cyan : const Color(0xFF5C5C5C), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ])),
    );
  }
}

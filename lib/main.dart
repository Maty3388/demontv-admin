import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api.dart';
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
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminApi.loadToken();
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
    title: 'FluxTv Panel',
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // 0=Panel, 1=Monitor, 2=Canales, 3=Resellers, 4=Movies, 5=Series, 6=Logs, 7=Update, 8=Ruleta
  final _screens = const [
    DashboardScreen(),
    MonitorScreen(),
    ChannelsScreen(),
    ResellersScreen(),
    MoviesScreen(),
    SeriesAdminScreen(),
    LogsScreen(),
    VersionScreen(),
    SpinScreen(),
    const AdminChatScreen(),
  ];

  final _titles = const [
    'Panel', 'Monitor', 'Canales', 'Resellers',
    'Películas', 'Series', 'Logs', 'Actualización', 'Ruleta', 'Chat',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    key: _scaffoldKey,
    backgroundColor: AdminTheme.bg,
    drawer: _buildDrawer(context),
    body: IndexedStack(index: _idx, children: _screens),
    bottomNavigationBar: _buildNav(),
  );

  Widget _buildNav() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0D0D0D),
      border: Border(top: BorderSide(color: AdminTheme.border, width: 0.5)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2))],
    ),
    child: SafeArea(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _NavBtn(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Panel', index: 0, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.monitor_outlined, activeIcon: Icons.monitor, label: 'Monitor', index: 1, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv, label: 'Canales', index: 2, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.store_outlined, activeIcon: Icons.store, label: 'Resellers', index: 3, selected: _idx, onTap: (i) => setState(() => _idx = i)),
        _NavBtn(icon: Icons.menu, activeIcon: Icons.menu_open, label: 'Más', index: -1, selected: _idx, onTap: (_) => _scaffoldKey.currentState?.openDrawer()),
      ]),
    )),
  );

  Widget _buildDrawer(BuildContext context) => Drawer(
    backgroundColor: const Color(0xFF0D0D0D),
    child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF7B2FFF), Color(0xFFFF9500)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.all_inclusive, color: Colors.white, size: 26)),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FluxTv Panel', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Admin', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      ),
      const SizedBox(height: 8),
      // Items del drawer
      _DrawerItem(icon: Icons.movie_outlined, label: 'Películas', selected: _idx == 4, onTap: () { setState(() => _idx = 4); Navigator.pop(context); }),
      _DrawerItem(icon: Icons.tv_outlined, label: 'Series', selected: _idx == 5, onTap: () { setState(() => _idx = 5); Navigator.pop(context); }),
      _DrawerItem(icon: Icons.history_outlined, label: 'Logs', selected: _idx == 6, onTap: () { setState(() => _idx = 6); Navigator.pop(context); }),
      _DrawerItem(icon: Icons.system_update_outlined, label: 'Actualización App', selected: _idx == 7, onTap: () { setState(() => _idx = 7); Navigator.pop(context); }),
      _DrawerItem(icon: Icons.casino_outlined, label: 'Ruleta', selected: _idx == 8, onTap: () { setState(() => _idx = 8); Navigator.pop(context); }),
      _DrawerItem(icon: Icons.chat_outlined, label: 'Chat', selected: _idx == 9, onTap: () { setState(() => _idx = 9); Navigator.pop(context); }),
      const Spacer(),
      const Divider(color: Color(0xFF2C2C2E)),
      // Cerrar sesión
      ListTile(
        leading: const Icon(Icons.logout, color: AdminTheme.red, size: 22),
        title: const Text('Cerrar Sesión', style: TextStyle(color: AdminTheme.red, fontWeight: FontWeight.w600)),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('admin_token');
          AdminApi.token = null;
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        },
      ),
      const SizedBox(height: 8),
    ])),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AdminTheme.cyan.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isSelected ? activeIcon : icon, size: 22,
            color: isSelected ? AdminTheme.cyan : const Color(0xFF5C5C5C)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? AdminTheme.cyan : const Color(0xFF5C5C5C),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: selected ? AdminTheme.cyan : const Color(0xFF5C5C5C), size: 22),
    title: Text(label, style: TextStyle(color: selected ? AdminTheme.cyan : Colors.white, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
    selected: selected,
    selectedTileColor: AdminTheme.cyan.withOpacity(0.08),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    onTap: onTap,
  );
}

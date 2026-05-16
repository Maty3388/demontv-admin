import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
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
    initialRoute: '/login',
    routes: {
      '/login':     (_) => const AdminLoginScreen(),
      '/dashboard': (_) => const DashboardScreen(),
    },
  );
}

import 'package:flutter/material.dart';

class AdminTheme {
  static const bg         = Color(0xFF0A0A0A);
  static const surface    = Color(0xFF1C1C1E);
  static const surfaceAlt = Color(0xFF2A2A2E);
  static const border     = Color(0xFF3A3A3E);
  static const textPrimary    = Colors.white;
  static const textSecondary  = Color(0xFF9E9E9E);
  static const textHint       = Color(0xFF5C5C5C);
  static const cyan    = Color(0xFF00CFDD);
  static const gold    = Color(0xFFFFD700);
  static const red     = Color(0xFFFF3B30);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(background: bg, surface: surface, primary: cyan),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111111),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: surfaceAlt,
      border: UnderlineInputBorder(borderSide: BorderSide(color: border)),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: border)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: cyan)),
      hintStyle: const TextStyle(color: textHint),
    ),
  );
}

class BalanceCard extends StatelessWidget {
  final int balance, extras;
  const BalanceCard({super.key, required this.balance, required this.extras});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A6FE3), Color(0xFF7B2FFF), Color(0xFFFF9500)],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('SALDO', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.monetization_on_outlined, color: Colors.white, size: 26),
          const SizedBox(width: 6),
          Text('$balance', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text('✨ Extras: $extras', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
        child: const Text('VENDEDOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
      ),
    ]),
  );
}

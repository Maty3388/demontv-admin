import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});
  @override State<SpinScreen> createState() => _State();
}

class _State extends State<SpinScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _spinning = false;
  int _spins = 0;
  int _balance = 0;
  String? _result;
  double _currentAngle = 0;
  bool _loading = true;

  final List<_Slice> slices = [
    _Slice('100\nCRÉDITOS', const Color(0xFF5BB8F5)),
    _Slice('50\nCRÉDITOS',  const Color(0xFF7DD8F0)),
    _Slice('SIGUE\nINTENTANDO', const Color(0xFFFFAA44)),
    _Slice('5\nCRÉDITOS',   const Color(0xFFFFCC44)),
    _Slice('10\nCRÉDITOS',  const Color(0xFFAA66FF)),
    _Slice('20\nCRÉDITOS',  const Color(0xFF8844EE)),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final r = await AdminApi.getStats();
      setState(() { _spins = r['spins'] ?? 0; _balance = r['balance'] ?? 0; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _spin() async {
    if (_spinning || _spins <= 0) return;
    setState(() { _spinning = true; _result = null; });
    try {
      final r = await AdminApi.spin();
      final prizeIndex = r['prize']?['index'] ?? 5;
      final targetAngle = _currentAngle + (4 * 2 * pi) + (prizeIndex * (2 * pi / slices.length));
      _anim = Tween<double>(begin: _currentAngle, end: targetAngle).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.reset();
      _ctrl.forward();
      _ctrl.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _spinning = false;
            _currentAngle = targetAngle % (2 * pi);
            _spins = r['spins'] ?? _spins - 1;
            _balance = r['balance'] ?? _balance;
            _result = r['prize']?['label'] ?? '';
          });
        }
      });
    } catch (_) { setState(() => _spinning = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(title: const Text('Ruleta de Premios')),
    body: _loading ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan)) : SafeArea(
      child: Column(children: [
        const SizedBox(height: 20),
        const Text('🎰 Juega y Gana 🎰', style: TextStyle(color: AdminTheme.gold, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Gira la ruleta y gana créditos gratis', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(border: Border.all(color: AdminTheme.gold, width: 1.5), borderRadius: BorderRadius.circular(24)),
            child: Text('Giros: $_spins', style: const TextStyle(color: AdminTheme.gold, fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(width: 16),
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(border: Border.all(color: AdminTheme.cyan, width: 1.5), borderRadius: BorderRadius.circular(24)),
            child: Text('Saldo: $_balance', style: const TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold, fontSize: 16))),
        ]),
        const SizedBox(height: 24),
        Expanded(child: Center(child: AnimatedBuilder(
          animation: _anim,
          builder: (ctx, _) => Transform.rotate(
            angle: _anim.value,
            child: CustomPaint(size: const Size(300, 300), painter: _WheelPainter(slices: slices)),
          ),
        ))),
        if (_result != null) ...[
          const SizedBox(height: 12),
          Text(_result!, textAlign: TextAlign.center, style: const TextStyle(color: AdminTheme.cyan, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GestureDetector(
            onTap: _spin,
            child: Container(height: 54, width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _spins > 0 ? [const Color(0xFF00BFFF), const Color(0xFFFFD700)] : [AdminTheme.surfaceAlt, AdminTheme.surface], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Center(child: Text('¡GIRAR!', style: TextStyle(color: _spins > 0 ? Colors.black : AdminTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1))),
            ),
          )),
        const SizedBox(height: 32),
      ]),
    ),
  );
}

class _Slice {
  final String label;
  final Color color;
  const _Slice(this.label, this.color);
}

class _WheelPainter extends CustomPainter {
  final List<_Slice> slices;
  const _WheelPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep = 2 * pi / slices.length;
    canvas.drawCircle(center, radius + 12, Paint()..color = const Color(0xFF7B44FF));
    for (int i = 0; i < 24; i++) {
      final a = (2 * pi / 24) * i;
      final p = Offset(center.dx + (radius + 6) * cos(a), center.dy + (radius + 6) * sin(a));
      canvas.drawCircle(p, 4, Paint()..color = const Color(0xFFFFD700));
    }
    for (int i = 0; i < slices.length; i++) {
      final start = i * sweep - pi / 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, Paint()..color = slices[i].color..style = PaintingStyle.fill);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, true, Paint()..color = Colors.white.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      final mid = start + sweep / 2;
      final tp = center + Offset(cos(mid) * radius * 0.65, sin(mid) * radius * 0.65);
      final span = TextSpan(text: slices[i].label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.2));
      final tp2 = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout(maxWidth: 70);
      canvas.save();
      canvas.translate(tp.dx, tp.dy);
      canvas.rotate(mid + pi / 2);
      tp2.paint(canvas, Offset(-tp2.width / 2, -tp2.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(center, 36, Paint()..color = Colors.black);
    final sp = TextSpan(text: 'GIRA', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1));
    final tp3 = TextPainter(text: sp, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
    tp3.paint(canvas, center - Offset(tp3.width / 2, tp3.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

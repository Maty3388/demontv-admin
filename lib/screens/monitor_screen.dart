import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});
  @override State<MonitorScreen> createState() => _State();
}

class _State extends State<MonitorScreen> {
  Map _watching = {};
  Map _stats = {};
  bool _loading = true;
  Timer? _timer;
  Timer? _clockTimer;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _timer?.cancel(); _clockTimer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final w = await AdminApi.getWatching();
      final s = await AdminApi.getStats();
      if (mounted) setState(() { _watching = w; _stats = s; _loading = false; _lastUpdate = DateTime.now(); });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  String get _lastUpdateStr {
    final diff = DateTime.now().difference(_lastUpdate);
    if (diff.inSeconds < 60) return 'hace \${diff.inSeconds}s';
    return 'hace \${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      backgroundColor: AdminTheme.surface,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Monitor en Vivo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text('Actualizado \$_lastUpdateStr', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
      ]),
      actions: [
        Container(margin: const EdgeInsets.only(right: 8),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
            const SizedBox(width: 4),
            const Text('EN VIVO', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
          ])),
        IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.cyan), onPressed: _load),
      ],
    ),
    body: _loading ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan)) : RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.cyan,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          _StatCard('Viendo', '\${_watching['count'] ?? 0}', Icons.play_circle, AdminTheme.cyan),
          const SizedBox(width: 10),
          _StatCard('Activos', '\${_stats['activos'] ?? 0}', Icons.check_circle, Colors.green),
          const SizedBox(width: 10),
          _StatCard('Vencidos', '\${_stats['vencidos'] ?? 0}', Icons.cancel, AdminTheme.red),
          const SizedBox(width: 10),
          _StatCard('Total', '\${_stats['total'] ?? 0}', Icons.people, AdminTheme.gold),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
              const SizedBox(width: 8),
              Text('Viendo ahora (\${_watching['count'] ?? 0})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text('↻ cada 10s', style: const TextStyle(color: AdminTheme.textHint, fontSize: 10)),
            ]),
            const SizedBox(height: 12),
            if ((_watching['viewers'] as List?)?.isEmpty ?? true)
              const Center(child: Padding(padding: EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.tv_off, color: AdminTheme.textHint, size: 40),
                  SizedBox(height: 8),
                  Text('Nadie viendo ahora', style: TextStyle(color: AdminTheme.textSecondary)),
                ])))
            else
              ...(_watching['viewers'] as List).map((v) => _ViewerTile(viewer: v, onRefresh: _load)),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Resumen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            _StatsRow('Activos', _stats['activos'] ?? 0, Colors.green),
            _StatsRow('Vencidos', _stats['vencidos'] ?? 0, AdminTheme.red),
            _StatsRow('Por vencer (5 días)', _stats['porVencer'] ?? 0, AdminTheme.gold),
            _StatsRow('Bloqueados', _stats['bloqueados'] ?? 0, Colors.orange),
          ]),
        ),
      ]),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 9), textAlign: TextAlign.center),
    ]),
  ));
}

class _ViewerTile extends StatelessWidget {
  final Map viewer;
  final VoidCallback onRefresh;
  const _ViewerTile({required this.viewer, required this.onRefresh});

  String _timeAgo(String iso) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso));
      if (diff.inSeconds < 60) return '\${diff.inSeconds}s';
      if (diff.inMinutes < 60) return '\${diff.inMinutes}m';
      return '\${diff.inHours}h';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.green.withOpacity(0.2))),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(viewer['email'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.tv, size: 11, color: AdminTheme.textSecondary),
          const SizedBox(width: 4),
          Expanded(child: Text(viewer['channelName'] ?? 'Desconocido', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        if (viewer['device'] != null) ...[
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.phone_android, size: 11, color: AdminTheme.textHint),
            const SizedBox(width: 4),
            Text(viewer['device'].toString(), style: const TextStyle(color: AdminTheme.textHint, fontSize: 10)),
          ]),
        ],
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(_timeAgo(viewer['since'] ?? ''), style: const TextStyle(color: AdminTheme.textHint, fontSize: 10)),
        const SizedBox(height: 4),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
          child: const Text('EN VIVO', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold))),
      ]),
    ]));
}

class _StatsRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatsRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13))),
      Text('\$value', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    ]),
  );
}

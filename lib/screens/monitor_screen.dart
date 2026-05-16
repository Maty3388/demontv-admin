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

  @override
  void initState() { super.initState(); _load(); _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load()); }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final w = await AdminApi.getWatching();
      final s = await AdminApi.getStats();
      setState(() { _watching = w; _stats = s; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      title: const Text('Monitoreo en Vivo'),
      actions: [IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.cyan), onPressed: _load)],
    ),
    body: _loading ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan)) : RefreshIndicator(
      onRefresh: _load,
      color: AdminTheme.cyan,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Stats cards
        Row(children: [
          _StatCard('Viendo ahora', '${_stats['watching'] ?? 0}', Icons.play_circle, AdminTheme.cyan),
          const SizedBox(width: 12),
          _StatCard('Activos', '${_stats['activos'] ?? 0}', Icons.check_circle, Colors.green),
          const SizedBox(width: 12),
          _StatCard('Total', '${_stats['total'] ?? 0}', Icons.people, AdminTheme.gold),
        ]),
        const SizedBox(height: 20),
        // Viewers activos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
              const SizedBox(width: 8),
              Text('Viendo en este momento (${_watching['count'] ?? 0})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            if ((_watching['viewers'] as List?)?.isEmpty ?? true)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Nadie viendo ahora', style: TextStyle(color: AdminTheme.textSecondary))))
            else
              ...(_watching['viewers'] as List).map((v) => _ViewerTile(viewer: v)),
          ]),
        ),
        const SizedBox(height: 16),
        // Stats detalladas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Resumen de clientes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3), width: 1)),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 10), textAlign: TextAlign.center),
    ]),
  ));
}

class _ViewerTile extends StatelessWidget {
  final Map viewer;
  const _ViewerTile({required this.viewer});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(viewer['email'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
        Text('📺 ${viewer['channelName'] ?? 'Desconocido'}', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
      ])),
      Text(_timeAgo(viewer['since'] ?? ''), style: const TextStyle(color: AdminTheme.textHint, fontSize: 10)),
    ]),
  );

  String _timeAgo(String iso) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso));
      if (diff.inMinutes < 1) return 'ahora';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      return '${diff.inHours}h';
    } catch (_) { return ''; }
  }
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
      Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    ]),
  );
}

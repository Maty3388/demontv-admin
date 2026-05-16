import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override State<LogsScreen> createState() => _State();
}

class _State extends State<LogsScreen> {
  List _logs = [];
  bool _loading = true;
  String _filter = 'all';

  final _filters = {
    'all': 'Todos',
    'client_created': 'Creados',
    'demo_created': 'Demos',
    'subscription_extended': 'Renovados',
    'client_blocked': 'Bloqueados',
    'client_deleted': 'Eliminados',
    'channel_added': 'Canales',
    'spin_win': 'Ruleta',
    'login': 'Logins',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await AdminApi.getLogs(type: _filter == 'all' ? null : _filter, limit: 100);
      setState(() => _logs = r['logs'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  IconData _icon(String type) {
    switch (type) {
      case 'client_created': return Icons.person_add;
      case 'demo_created': return Icons.person_add_outlined;
      case 'subscription_extended': return Icons.calendar_month;
      case 'client_blocked': return Icons.block;
      case 'client_deleted': return Icons.delete;
      case 'channel_added': return Icons.live_tv;
      case 'channel_deleted': return Icons.delete_outline;
      case 'spin_win': return Icons.star;
      case 'spin_lose': return Icons.refresh;
      case 'login': return Icons.login;
      case 'password_changed': return Icons.lock;
      default: return Icons.info;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'client_created': return Colors.green;
      case 'demo_created': return AdminTheme.cyan;
      case 'subscription_extended': return AdminTheme.gold;
      case 'client_blocked': return Colors.orange;
      case 'client_deleted': return AdminTheme.red;
      case 'channel_added': return Colors.blue;
      case 'spin_win': return AdminTheme.gold;
      case 'login': return Colors.purple;
      default: return AdminTheme.textSecondary;
    }
  }

  String _label(String type) => _filters[type] ?? type;

  String _timeAgo(String iso) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso));
      if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
      if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'hace ${diff.inHours}h';
      return 'hace ${diff.inDays}d';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      title: const Text('Registro de Actividad'),
      actions: [IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.cyan), onPressed: _load)],
    ),
    body: Column(children: [
      // Filtros
      SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _filters.entries.map((e) => GestureDetector(
          onTap: () { setState(() => _filter = e.key); _load(); },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _filter == e.key ? AdminTheme.cyan : AdminTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(e.value, style: TextStyle(color: _filter == e.key ? Colors.black : AdminTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        )).toList(),
      )),
      // Lista
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
        : _logs.isEmpty
          ? const Center(child: Text('Sin registros', style: TextStyle(color: AdminTheme.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemCount: _logs.length,
              itemBuilder: (ctx, i) {
                final log = _logs[i];
                final type = log['type'] ?? '';
                final data = log['data'] as Map? ?? {};
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: _color(type).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_icon(type), color: _color(type), size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_label(type), style: TextStyle(color: _color(type), fontSize: 12, fontWeight: FontWeight.bold)),
                      if (data['email'] != null) Text(data['email'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                      if (data['name'] != null) Text(data['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                      if (data['prize'] != null) Text(data['prize'], style: const TextStyle(color: AdminTheme.gold, fontSize: 12)),
                    ])),
                    Text(_timeAgo(log['timestamp'] ?? ''), style: const TextStyle(color: AdminTheme.textHint, fontSize: 10)),
                  ]),
                );
              },
            )),
    ]),
  );
}

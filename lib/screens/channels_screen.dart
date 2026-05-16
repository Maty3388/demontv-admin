import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';
import 'import_m3u_screen.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});
  @override State<ChannelsScreen> createState() => _State();
}

class _State extends State<ChannelsScreen> {
  List _channels = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await AdminApi.getChannels();
      setState(() => _channels = r['channels'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showAdd() => showDialog(context: context, builder: (_) => _AddChannelDialog(onAdded: _load));
  void _showImport() => Navigator.push(context, MaterialPageRoute(builder: (_) => ImportM3uScreen(onImported: _load)));

  void _confirmDelete(Map ch) => showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Eliminar canal?', style: TextStyle(color: Colors.white)),
    content: Text(ch['name'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: () async { await AdminApi.deleteChannel(ch['id']); Navigator.pop(ctx); _load(); },
        child: const Text('ELIMINAR', style: TextStyle(color: AdminTheme.red, fontWeight: FontWeight.bold))),
    ],
  ));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      title: Text('Canales (${_channels.length})'),
      actions: [
        IconButton(icon: const Icon(Icons.playlist_add, color: AdminTheme.gold), onPressed: _showImport),
        IconButton(icon: const Icon(Icons.add_circle_outline, color: AdminTheme.cyan), onPressed: _showAdd),
        IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.cyan), onPressed: _load),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
      : _channels.isEmpty
        ? const Center(child: Text('Sin canales', style: TextStyle(color: AdminTheme.textSecondary)))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const Divider(color: AdminTheme.border, height: 1),
            itemCount: _channels.length,
            itemBuilder: (ctx, i) {
              final ch = _channels[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(8)),
                  child: ch['logo']?.isNotEmpty == true
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ch['logo'], fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: AdminTheme.textHint)))
                    : const Icon(Icons.tv, color: AdminTheme.textHint)),
                title: Text(ch['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(ch['category'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AdminTheme.red, size: 20), onPressed: () => _confirmDelete(ch)),
              );
            }),
  );
}

class _AddChannelDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddChannelDialog({required this.onAdded});
  @override State<_AddChannelDialog> createState() => _AddState();
}

class _AddState extends State<_AddChannelDialog> {
  final _name = TextEditingController();
  final _cat  = TextEditingController();
  final _logo = TextEditingController();
  final _url  = TextEditingController();
  bool _verifying = false, _adding = false;
  Map? _verifyResult;
  String? _error;

  Future<void> _verify() async {
    if (_url.text.isEmpty) { setState(() => _error = 'URL requerida'); return; }
    setState(() { _verifying = true; _error = null; _verifyResult = null; });
    final r = await AdminApi.verifyStream(_url.text.trim());
    setState(() { _verifyResult = r; _verifying = false; });
    if (r['ok'] != true) setState(() => _error = 'Stream no responde: ${r['error'] ?? 'HTTP ${r['status']}'}');
  }

  Future<void> _add() async {
    if (_name.text.isEmpty || _url.text.isEmpty) { setState(() => _error = 'Nombre y URL requeridos'); return; }
    setState(() { _adding = true; _error = null; });
    final r = await AdminApi.addChannel(_name.text.trim(), _cat.text.trim().isNotEmpty ? _cat.text.trim() : 'General', _logo.text.trim(), _url.text.trim());
    setState(() => _adding = false);
    if (r['success'] == true) { widget.onAdded(); Navigator.pop(context); }
    else setState(() => _error = r['error'] ?? 'Error');
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Agregar Canal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_name, 'Nombre del canal *'),
      _field(_cat, 'Categoria (ej: DEPORTES)'),
      _field(_logo, 'URL del logo'),
      _field(_url, 'URL del stream *'),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _verifying ? null : _verify,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(border: Border.all(color: _verifyResult != null ? (_verifyResult!['ok'] == true ? Colors.green : AdminTheme.red) : AdminTheme.cyan), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_verifying) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan)),
            if (_verifyResult != null && !_verifying) Icon(_verifyResult!['ok'] == true ? Icons.check_circle : Icons.cancel, color: _verifyResult!['ok'] == true ? Colors.green : AdminTheme.red, size: 16),
            const SizedBox(width: 6),
            Text(_verifyResult == null ? 'Verificar stream' : (_verifyResult!['ok'] == true ? 'Activo' : 'Inactivo'),
              style: TextStyle(color: _verifyResult == null ? AdminTheme.cyan : (_verifyResult!['ok'] == true ? Colors.green : AdminTheme.red), fontSize: 13)),
          ])),
      ),
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 12), textAlign: TextAlign.center)],
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: _adding ? null : _add,
        child: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
            : const Text('AGREGAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );

  Widget _field(TextEditingController c, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))));
}

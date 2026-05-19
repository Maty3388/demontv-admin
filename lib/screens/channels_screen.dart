import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';
import 'import_m3u_screen.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});
  @override State<ChannelsScreen> createState() => _CS();
}

class _CS extends State<ChannelsScreen> {
  List _ch = [];
  bool _loading = true;
  String _msg = '';
  bool _msgOk = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await AdminApi.getChannels();
    setState(() { _ch = r['channels'] ?? []; _loading = false; });
  }

  void _showMsg(String msg, bool ok) => setState(() { _msg = msg; _msgOk = ok; });

  void _delete(String id) {
    AdminApi.loadToken().then((_) => AdminApi.deleteChannel(id).then((r) {
      if (!mounted) return;
      if (r['success'] == true) { _load(); _showMsg('Canal eliminado', true); }
      else _showMsg('Error: ${r['error'] ?? r.toString()}', false);
    }).catchError((e) { if (mounted) _showMsg('Error: $e', false); }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bg,
      appBar: AppBar(
        backgroundColor: AdminTheme.surface,
        title: Text('Canales (${_ch.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AdminTheme.cyan), onPressed: () async {
            await showDialog(context: context, builder: (_) => _AddDialog(onAdded: _load));
          }),
          IconButton(icon: const Icon(Icons.playlist_add, color: AdminTheme.gold), onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => ImportM3uScreen(onImported: _load)));
          }),
          IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.textSecondary), onPressed: _load),
        ],
      ),
      body: Column(children: [
        if (_msg.isNotEmpty) Container(
          width: double.infinity, color: _msgOk ? Colors.green : Colors.red,
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(child: Text(_msg, style: const TextStyle(color: Colors.white))),
            GestureDetector(onTap: () => setState(() => _msg = ''), child: const Icon(Icons.close, color: Colors.white, size: 16)),
          ])),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
          : _ch.isEmpty
            ? const Center(child: Text('No hay canales', style: TextStyle(color: AdminTheme.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _ch.length,
                itemBuilder: (ctx, i) {
                  final c = _ch[i];
                  final id = (c['_id'] ?? c['id'] ?? '').toString().replaceAll('ObjectId(', '').replaceAll(')', '').replaceAll("'", '').trim();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminTheme.border, width: 0.5)),
                    child: Row(children: [
                      Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                        child: c['logo']?.isNotEmpty == true
                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(c['logo'], fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: AdminTheme.textHint, size: 20)))
                          : const Icon(Icons.tv, color: AdminTheme.textHint, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(c['category'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
                      ])),
                      IconButton(icon: const Icon(Icons.edit_outlined, color: AdminTheme.cyan, size: 20), onPressed: () async {
                        await showDialog(context: context, builder: (_) => _EditDialog(id: id, channel: c, onEdited: () { _load(); _showMsg('Canal actualizado', true); }));
                      }),
                      IconButton(icon: const Icon(Icons.delete_outline, color: AdminTheme.red, size: 20), onPressed: () => _delete(id)),
                    ]),
                  );
                })),
      ]),
    );
  }
}

class _AddDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddDialog({required this.onAdded});
  @override State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  final _name = TextEditingController();
  final _cat  = TextEditingController();
  final _logo = TextEditingController();
  final _url  = TextEditingController();
  bool _loading = false;
  String? _error;

  @override void dispose() { _name.dispose(); _cat.dispose(); _logo.dispose(); _url.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Agregar Canal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_name, 'Nombre *'), _field(_cat, 'Categoria'), _field(_logo, 'URL Logo'), _field(_url, 'URL Stream *'),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AdminTheme.red))),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(
        onPressed: _loading ? null : () async {
          if (_name.text.isEmpty || _url.text.isEmpty) { setState(() => _error = 'Nombre y URL requeridos'); return; }
          setState(() { _loading = true; _error = null; });
          final r = await AdminApi.addChannel(_name.text.trim(), _cat.text.trim().isNotEmpty ? _cat.text.trim() : 'General', _logo.text.trim(), _url.text.trim());
          if (!mounted) return;
          setState(() => _loading = false);
          if (r['success'] == true) { widget.onAdded(); Navigator.pop(context); }
          else setState(() => _error = r['error'] ?? 'Error');
        },
        child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan)) : const Text('AGREGAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );

  Widget _field(TextEditingController c, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))));
}

class _EditDialog extends StatefulWidget {
  final String id;
  final Map channel;
  final VoidCallback onEdited;
  const _EditDialog({required this.id, required this.channel, required this.onEdited});
  @override State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _name = TextEditingController(text: widget.channel['name'] ?? '');
  late final _cat  = TextEditingController(text: widget.channel['category'] ?? '');
  late final _logo = TextEditingController(text: widget.channel['logo'] ?? '');
  late final _url  = TextEditingController(text: widget.channel['stream_url'] ?? '');
  bool _loading = false;
  String? _error;

  @override void dispose() { _name.dispose(); _cat.dispose(); _logo.dispose(); _url.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Editar Canal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_name, 'Nombre *'), _field(_cat, 'Categoria'), _field(_logo, 'URL Logo'), _field(_url, 'URL Stream *'),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AdminTheme.red))),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(
        onPressed: _loading ? null : () async {
          if (_name.text.isEmpty || _url.text.isEmpty) { setState(() => _error = 'Nombre y URL requeridos'); return; }
          setState(() { _loading = true; _error = null; });
          final r = await AdminApi.updateChannel(widget.id, _name.text.trim(), _cat.text.trim().isNotEmpty ? _cat.text.trim() : 'General', _logo.text.trim(), _url.text.trim());
          if (!mounted) return;
          setState(() => _loading = false);
          if (r['success'] == true) { widget.onEdited(); Navigator.pop(context); }
          else setState(() => _error = r['error'] ?? 'Error');
        },
        child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan)) : const Text('GUARDAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );

  Widget _field(TextEditingController c, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))));
}

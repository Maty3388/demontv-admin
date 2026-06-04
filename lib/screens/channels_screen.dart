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
  List _filtered = [];
  bool _loading = true;
  String _msg = '';
  bool _msgOk = true;
  String _search = '';
  String _catFilter = 'Todos';
  List<String> _categories = ['Todos'];
  final _searchCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await AdminApi.getChannels();
    final all = r['channels'] ?? [];
    final cats = ['Todos', ...{...all.map((c) => c['category']?.toString() ?? 'General')}.toList()..sort()];
    setState(() { _ch = all; _categories = cats; _applyFilter(); _loading = false; });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _ch.where((c) {
        final matchCat = _catFilter == 'Todos' || c['category'] == _catFilter;
        final matchSearch = _search.isEmpty || (c['name'] ?? '').toLowerCase().contains(_search.toLowerCase());
        return matchCat && matchSearch;
      }).toList();
    });
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
        title: Text('Canales (${_filtered.length}/${_ch.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AdminTheme.cyan), onPressed: () async {
            await showDialog(context: context, builder: (_) => _AddDialog(onAdded: _load));
          }),
          IconButton(icon: const Icon(Icons.playlist_add, color: AdminTheme.gold), onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => ImportM3uScreen(onImported: _load)));
          }),
          IconButton(icon: const Icon(Icons.link, color: Colors.purple), onPressed: () async {
            await showDialog(context: context, builder: (_) => _ImportUrlDialog(onImported: _load));
          }),
          IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.textSecondary), onPressed: _load),
        ],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12,8,12,4), child: Row(children: [
          Expanded(child: TextField(
            controller: _searchCtrl,
            onChanged: (v) { _search = v; _applyFilter(); },
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF5C5C5C)),
              hintText: 'Buscar canal...', hintStyle: const TextStyle(color: Color(0xFF5C5C5C), fontSize: 13),
              filled: true, fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _catFilter,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            underline: const SizedBox(),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) { if (v != null) { _catFilter = v; _applyFilter(); } }),
        ])),
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
            : _filtered.isEmpty
              ? const Center(child: Text('Sin resultados', style: TextStyle(color: Color(0xFF5C5C5C))))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final c = _filtered[i];
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
                      IconButton(icon: const Icon(Icons.delete_outline, color: AdminTheme.red, size: 20), onPressed: () {
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E1E),
                          title: const Text('Eliminar canal', style: TextStyle(color: Colors.white)),
                          content: Text('¿Eliminar "${c['name']}"?', style: const TextStyle(color: Color(0xFF9E9E9E))),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E)))),
                            TextButton(onPressed: () { Navigator.pop(ctx); _delete(id); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                          ]));
                      }),
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

class _ImportUrlDialog extends StatefulWidget {
  final VoidCallback onImported;
  const _ImportUrlDialog({required this.onImported});
  @override State<_ImportUrlDialog> createState() => _ImportUrlState();
}

class _ImportUrlState extends State<_ImportUrlDialog> {
  final _url = TextEditingController();
  bool _loading = false;
  String? _error;
  String _msg = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Importar M3U desde URL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _url,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'https://...',
          prefixIcon: Icon(Icons.link, size: 18),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 12))],
      if (_msg.isNotEmpty) ...[const SizedBox(height: 8), Text(_msg, style: const TextStyle(color: Colors.green, fontSize: 12))],
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(
        onPressed: _loading ? null : () async {
          if (_url.text.isEmpty) { setState(() => _error = 'Ingresá una URL'); return; }
          setState(() { _loading = true; _error = null; _msg = ''; });
          try {
            final r = await AdminApi.fetchM3u(_url.text.trim());
            final channels = r['channels'] ?? [];
            setState(() { _msg = 'Importados \${channels.length} canales'; _loading = false; });
            widget.onImported();
          } catch (e) {
            setState(() { _error = 'Error: \$e'; _loading = false; });
          }
        },
        child: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
          : const Text('IMPORTAR', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
    ],
  );
}

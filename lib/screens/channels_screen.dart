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
  String _search = '';
  String _catFilter = 'Todos';
  List<String> _categories = ['Todos'];
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _selectMode = false;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _selected.clear(); _selectMode = false; });
    final r = await AdminApi.getChannels();
    final all = r['channels'] ?? [];
    final catSet = <String>{};
    for (final c in all) catSet.add(c['category']?.toString() ?? 'General');
    final cats = ['Todos', ...catSet.toList()..sort()];
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

  String _getId(dynamic c) => (c['_id'] ?? c['id'] ?? '').toString();

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) _selected.remove(id);
      else _selected.add(id);
      _selectMode = _selected.isNotEmpty;
    });
  }

  void _selectAll() {
    setState(() {
      if (_selected.length == _filtered.length) {
        _selected.clear(); _selectMode = false;
      } else {
        _selected.addAll(_filtered.map((c) => _getId(c)));
        _selectMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminTheme.surface,
      title: Text('Eliminar ${_selected.length} canales', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text('¿Eliminar ${_selected.length} canales seleccionados?', style: const TextStyle(color: AdminTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ELIMINAR', style: TextStyle(color: Color(0xFFCF6679), fontWeight: FontWeight.bold))),
      ]));
    if (confirm != true) return;
    int ok = 0;
    for (final id in _selected.toList()) {
      final r = await AdminApi.deleteChannel(id);
      if (r['success'] == true) ok++;
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ok canales eliminados'), backgroundColor: Colors.green));
    _load();
  }

  Future<void> _moveCategorySelected() async {
    final ctrl = TextEditingController();
    final newCat = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminTheme.surface,
      title: const Text('Mover a categoría', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${_selected.length} canales seleccionados', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        TextField(controller: ctrl, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Nombre de categoría', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
        const SizedBox(height: 8),
        SizedBox(height: 120, child: SingleChildScrollView(child: Wrap(spacing: 6, runSpacing: 6, children: _categories.where((c) => c != 'Todos').map((cat) =>
          GestureDetector(onTap: () => ctrl.text = cat, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(6)),
            child: Text(cat, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 10))))).toList()))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('MOVER', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
      ]));
    if (newCat == null || newCat.isEmpty) return;
    int ok = 0;
    for (final id in _selected.toList()) {
      final ch = _ch.firstWhere((c) => _getId(c) == id, orElse: () => {});
      if (ch.isEmpty) continue;
      final r = await AdminApi.updateChannel(id, ch['name']?.toString() ?? '', newCat, ch['logo']?.toString() ?? '', ch['stream_url']?.toString() ?? '', ch['drm_keys']?.toString() ?? '');
      if (r['success'] == true) ok++;
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ok canales movidos a $newCat'), backgroundColor: AdminTheme.cyan));
    _load();
  }

  Future<void> _deleteSingle(dynamic c) async {
    final id = _getId(c);
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminTheme.surface,
      title: const Text('¿Eliminar canal?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(c['name'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ELIMINAR', style: TextStyle(color: Color(0xFFCF6679), fontWeight: FontWeight.bold))),
      ]));
    if (confirm != true) return;
    final r = await AdminApi.deleteChannel(id);
    if (!mounted) return;
    if (r['success'] == true) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Canal eliminado'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${r['error'] ?? r.toString()}'), backgroundColor: const Color(0xFFCF6679)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      backgroundColor: AdminTheme.surface,
      leading: _selectMode ? IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() { _selected.clear(); _selectMode = false; })) : null,
      title: _selectMode
        ? Text('${_selected.length} seleccionados', style: const TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))
        : Text('Canales (${_filtered.length}/${_ch.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: _selectMode ? [
        IconButton(icon: const Icon(Icons.select_all, color: AdminTheme.cyan), tooltip: 'Seleccionar todos', onPressed: _selectAll),
        IconButton(icon: const Icon(Icons.drive_file_move_outlined, color: AdminTheme.gold), tooltip: 'Mover categoría', onPressed: _moveCategorySelected),
        IconButton(icon: const Icon(Icons.delete_sweep, color: Color(0xFFCF6679)), tooltip: 'Eliminar seleccionados', onPressed: _deleteSelected),
      ] : [
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
      Padding(padding: const EdgeInsets.fromLTRB(12,8,12,4), child: TextField(
        controller: _searchCtrl,
        onChanged: (v) { _search = v; _applyFilter(); },
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF5C5C5C)),
          hintText: 'Buscar canal...', hintStyle: const TextStyle(color: Color(0xFF5C5C5C), fontSize: 13),
          filled: true, fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
      SizedBox(height: 36, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = cat == _catFilter;
          return GestureDetector(
            onTap: () { setState(() => _catFilter = cat); _applyFilter(); },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AdminTheme.cyan.withOpacity(0.2) : AdminTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AdminTheme.cyan : Colors.transparent)),
              child: Text(cat, style: TextStyle(color: sel ? AdminTheme.cyan : AdminTheme.textSecondary, fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal))));
        })),
      const SizedBox(height: 4),
      if (_selectMode) Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: AdminTheme.cyan.withOpacity(0.08),
        child: Row(children: [
          const Icon(Icons.touch_app, color: AdminTheme.cyan, size: 14),
          const SizedBox(width: 6),
          Text('${_selected.length} seleccionados — mantené presionado para seleccionar más', style: const TextStyle(color: AdminTheme.cyan, fontSize: 11)),
        ])),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
        : _filtered.isEmpty
          ? const Center(child: Text('Sin canales', style: TextStyle(color: AdminTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final c = _filtered[i];
                final id = _getId(c);
                final isSelected = _selected.contains(id);
                return GestureDetector(
                  onLongPress: () => _toggleSelect(id),
                  onTap: () { if (_selectMode) _toggleSelect(id); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AdminTheme.cyan.withOpacity(0.15) : AdminTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AdminTheme.cyan : Colors.transparent, width: 1.5)),
                    child: Row(children: [
                      if (_selectMode) Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? AdminTheme.cyan : AdminTheme.textSecondary, size: 20)),
                      Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
                        child: c['logo']?.toString().isNotEmpty == true
                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(c['logo'].toString(), fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Text((c['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))))
                          : Center(child: Text((c['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(c['category'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 10)),
                      ])),
                      if (!_selectMode) Row(children: [
                        GestureDetector(
                          onTap: () => showDialog(context: context, builder: (_) => _EditDialog(channel: c, onEdited: _load)),
                          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.edit, color: AdminTheme.gold, size: 17))),
                        GestureDetector(
                          onTap: () => _deleteSingle(c),
                          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: Icon(Icons.delete_outline, color: Color(0xFFCF6679), size: 17))),
                      ]),
                    ])));
              })),
    ]));
}

class _AddDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddDialog({required this.onAdded});
  @override State<_AddDialog> createState() => _AddState();
}
class _AddState extends State<_AddDialog> {
  final _name = TextEditingController(), _logo = TextEditingController(), _url = TextEditingController(), _cat = TextEditingController(), _drmKeys = TextEditingController();
  bool _loading = false; String? _error;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Agregar Canal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _f(_name, 'Nombre *'), _f(_cat, 'Categoría'), _f(_logo, 'URL Logo'), _f(_url, 'URL Stream'), _f(_drmKeys, 'Claves DRM (kid:key, opcional)'),
      if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFCF6679), fontSize: 12)),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: _loading ? null : () async {
        if (_name.text.isEmpty) { setState(() => _error = 'Nombre requerido'); return; }
        setState(() { _loading = true; _error = null; });
        final r = await AdminApi.addChannel(_name.text.trim(), _cat.text.trim().isEmpty ? 'General' : _cat.text.trim(), _logo.text.trim(), _url.text.trim(), _drmKeys.text.trim());
        setState(() => _loading = false);
        if (r['success'] == true) { widget.onAdded(); Navigator.pop(context); }
        else setState(() => _error = r['error'] ?? 'Error');
      }, child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan)) : const Text('AGREGAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ]);

  Widget _f(TextEditingController c, String h) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(hintText: h, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))));
}

class _EditDialog extends StatefulWidget {
  final dynamic channel; final VoidCallback onEdited;
  const _EditDialog({required this.channel, required this.onEdited});
  @override State<_EditDialog> createState() => _EditState();
}
class _EditState extends State<_EditDialog> {
  late final _name = TextEditingController(text: widget.channel['name']?.toString() ?? '');
  late final _logo = TextEditingController(text: widget.channel['logo']?.toString() ?? '');
  late final _url = TextEditingController(text: widget.channel['stream_url']?.toString() ?? '');
  late final _cat = TextEditingController(text: widget.channel['category']?.toString() ?? '');
  late final _drmKeys = TextEditingController(text: widget.channel['drm_keys']?.toString() ?? '');
  bool _loading = false; String? _error;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Editar Canal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _f(_name, 'Nombre'), _f(_cat, 'Categoría'), _f(_logo, 'URL Logo'), _f(_url, 'URL Stream'), _f(_drmKeys, 'Claves DRM (kid:key, opcional)'),
      if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFCF6679), fontSize: 12)),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: _loading ? null : () async {
        setState(() { _loading = true; _error = null; });
        final id = (widget.channel['_id'] ?? widget.channel['id'] ?? '').toString();
        final r = await AdminApi.updateChannel(id, _name.text.trim(), _cat.text.trim(), _logo.text.trim(), _url.text.trim(), _drmKeys.text.trim());
        setState(() => _loading = false);
        if (r['success'] == true) { widget.onEdited(); Navigator.pop(context); }
        else setState(() => _error = r['error'] ?? 'Error al actualizar');
      }, child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan)) : const Text('GUARDAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ]);

  Widget _f(TextEditingController c, String h) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(hintText: h, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))));
}

class _ImportUrlDialog extends StatefulWidget {
  final VoidCallback onImported;
  const _ImportUrlDialog({required this.onImported});
  @override State<_ImportUrlDialog> createState() => _ImportUrlState();
}
class _ImportUrlState extends State<_ImportUrlDialog> {
  final _url = TextEditingController();
  bool _loading = false; String? _error; String _msg = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Importar M3U desde URL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _url, style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(hintText: 'https://...', prefixIcon: Icon(Icons.link, size: 18), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8))),
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Color(0xFFCF6679), fontSize: 12))],
      if (_msg.isNotEmpty) ...[const SizedBox(height: 8), Text(_msg, style: const TextStyle(color: Colors.green, fontSize: 12))],
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: _loading ? null : () async {
        if (_url.text.isEmpty) { setState(() => _error = 'Ingresá una URL'); return; }
        setState(() { _loading = true; _error = null; _msg = ''; });
        try {
          final r = await AdminApi.fetchM3u(_url.text.trim());
          final channels = r['channels'] ?? [];
          setState(() { _msg = 'Importados ${channels.length} canales'; _loading = false; });
          widget.onImported();
        } catch (e) { setState(() { _error = 'Error: $e'; _loading = false; }); }
      }, child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan)) : const Text('IMPORTAR', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
    ]);
}

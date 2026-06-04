import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class SeriesAdminScreen extends StatefulWidget {
  const SeriesAdminScreen({super.key});
  @override State<SeriesAdminScreen> createState() => _State();
}

class _State extends State<SeriesAdminScreen> {
  List _series = [];
  List _filtered = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await AdminApi.getSeries();
      final all = r['series'] ?? [];
      setState(() { _series = all; _applyFilter(); });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _applyFilter() {
    setState(() => _filtered = _series.where((s) =>
      _search.isEmpty || (s['title'] ?? '').toLowerCase().contains(_search.toLowerCase())
    ).toList());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      backgroundColor: AdminTheme.surface,
      title: Text('Series (\${_filtered.length}/\${_series.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.cyan), onPressed: _load),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => showDialog(context: context, builder: (_) => _AddSeriesDialog(onAdded: _load)),
      backgroundColor: AdminTheme.cyan,
      child: const Icon(Icons.add, color: Colors.black)),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12,8,12,4), child: TextField(
        controller: _searchCtrl,
        onChanged: (v) { _search = v; _applyFilter(); },
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF5C5C5C)),
          hintText: 'Buscar serie...', hintStyle: const TextStyle(color: Color(0xFF5C5C5C), fontSize: 13),
          filled: true, fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
        : _filtered.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.tv, color: AdminTheme.textHint, size: 60),
              const SizedBox(height: 12),
              Text(_search.isEmpty ? 'Sin series' : 'Sin resultados', style: const TextStyle(color: AdminTheme.textSecondary)),
            ]))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.6),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) => _SeriesCard(series: _filtered[i], onRefresh: _load))),
    ]),
  );
}

class _SeriesCard extends StatelessWidget {
  final Map series;
  final VoidCallback onRefresh;
  const _SeriesCard({required this.series, required this.onRefresh});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => showDialog(context: context, builder: (_) => _EditSeriesDialog(series: series, onEdited: onRefresh)),
    child: Stack(children: [
      Container(
        decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: series['poster']?.isNotEmpty == true
              ? Image.network(series['poster'], fit: BoxFit.cover, width: double.infinity,
                  errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: AdminTheme.textHint, size: 40))
              : const Center(child: Icon(Icons.tv, color: AdminTheme.textHint, size: 40)))),
          Padding(padding: const EdgeInsets.all(4),
            child: Text(series['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9))),
        ]),
      ),
      Positioned(top: 4, right: 4, child: GestureDetector(
        onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: AdminTheme.surface,
          title: const Text('Eliminar serie?', style: TextStyle(color: Colors.white)),
          content: Text(series['title'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
            TextButton(onPressed: () async { await AdminApi.deleteSeries(series['_id'] ?? series['id'] ?? ''); Navigator.pop(ctx); onRefresh(); },
              child: const Text('ELIMINAR', style: TextStyle(color: AdminTheme.red, fontWeight: FontWeight.bold))),
          ])),
        child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.close, color: AdminTheme.red, size: 14)))),
      if (series['featured'] == true)
        Positioned(top: 4, left: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: AdminTheme.gold.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
          child: const Text('★', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)))),
    ]));
}

class _AddSeriesDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddSeriesDialog({required this.onAdded});
  @override State<_AddSeriesDialog> createState() => _AddSeriesState();
}
class _AddSeriesState extends State<_AddSeriesDialog> {
  final _title = TextEditingController(), _poster = TextEditingController(),
        _year = TextEditingController(), _genre = TextEditingController(),
        _desc = TextEditingController(), _cat = TextEditingController();
  bool _featured = false, _loading = false;
  String? _error;

  Future<void> _add() async {
    if (_title.text.isEmpty) { setState(() => _error = 'Titulo requerido'); return; }
    setState(() { _loading = true; _error = null; });
    final r = await AdminApi.addSeries({
      'title': _title.text.trim(), 'poster': _poster.text.trim(),
      'year': _year.text.trim(), 'genre': _genre.text.trim(),
      'description': _desc.text.trim(), 'featured': _featured,
      'category': _cat.text.trim().isEmpty ? 'General' : _cat.text.trim(),
    });
    setState(() => _loading = false);
    if (r['success'] == true) { widget.onAdded(); Navigator.pop(context); }
    else setState(() => _error = r['error'] ?? 'Error');
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Agregar Serie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_title, 'Titulo *'), _field(_poster, 'URL del poster'),
      _field(_cat, 'Categoria'), _field(_year, 'Año'), _field(_genre, 'Genero'),
      _field(_desc, 'Descripcion', maxLines: 2),
      Row(children: [Checkbox(value: _featured, onChanged: (v) => setState(() => _featured = v!), activeColor: AdminTheme.gold),
        const Text('Destacada', style: TextStyle(color: Colors.white))]),
      if (_error != null) Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 12)),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: _loading ? null : _add,
        child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
          : const Text('AGREGAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c, maxLines: maxLines, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))));
}

class _EditSeriesDialog extends StatefulWidget {
  final Map series;
  final VoidCallback onEdited;
  const _EditSeriesDialog({required this.series, required this.onEdited});
  @override State<_EditSeriesDialog> createState() => _EditSeriesState();
}
class _EditSeriesState extends State<_EditSeriesDialog> {
  late final _title = TextEditingController(text: widget.series['title'] ?? '');
  late final _poster = TextEditingController(text: widget.series['poster'] ?? '');
  late final _cat = TextEditingController(text: widget.series['category'] ?? '');
  late bool _featured = widget.series['featured'] == true;
  bool _loading = false;
  String? _error;

  Future<void> _save() async {
    setState(() { _loading = true; _error = null; });
    final r = await AdminApi.addSeries({
      'title': _title.text.trim(), 'poster': _poster.text.trim(),
      'featured': _featured, 'category': _cat.text.trim().isEmpty ? 'General' : _cat.text.trim(),
    });
    setState(() => _loading = false);
    if (r['success'] == true) { widget.onEdited(); Navigator.pop(context); }
    else setState(() => _error = r['error'] ?? 'Error');
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Editar Serie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_title, 'Titulo'), _field(_poster, 'URL poster'), _field(_cat, 'Categoria'),
      Row(children: [Checkbox(value: _featured, onChanged: (v) => setState(() => _featured = v!), activeColor: AdminTheme.gold),
        const Text('Destacada', style: TextStyle(color: Colors.white))]),
      if (_error != null) Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 12)),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: _loading ? null : _save,
        child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
          : const Text('GUARDAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );

  Widget _field(TextEditingController c, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))));
}

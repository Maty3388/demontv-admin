import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class SeriesAdminScreen extends StatefulWidget {
  const SeriesAdminScreen({super.key});
  @override State<SeriesAdminScreen> createState() => _State();
}

class _State extends State<SeriesAdminScreen> {
  List _series = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await AdminApi.getSeries();
      setState(() => _series = r['series'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      title: Text('Series (${_series.length})'),
      actions: [
        IconButton(icon: const Icon(Icons.add_circle_outline, color: AdminTheme.cyan), onPressed: _showAdd),
        IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.cyan), onPressed: _load),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
      : _series.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.tv, color: AdminTheme.textHint, size: 60),
            const SizedBox(height: 12),
            const Text('Sin series', style: TextStyle(color: AdminTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _showAdd, style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.cyan), child: const Text('Agregar', style: TextStyle(color: Colors.black))),
          ]))
        : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.6),
            itemCount: _series.length,
            itemBuilder: (ctx, i) => _SeriesCard(series: _series[i], onDelete: _load),
          ),
  );

  void _showAdd() => showDialog(context: context, builder: (_) => _AddSeriesDialog(onAdded: _load));
}

class _SeriesCard extends StatelessWidget {
  final Map series;
  final VoidCallback onDelete;
  const _SeriesCard({required this.series, required this.onDelete});

  @override
  Widget build(BuildContext context) => Stack(children: [
    Container(
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: series['poster']?.isNotEmpty == true
            ? Image.network(series['poster'], fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: AdminTheme.textHint, size: 40))
            : const Center(child: Icon(Icons.tv, color: AdminTheme.textHint, size: 40)))),
        Padding(padding: const EdgeInsets.all(4),
          child: Text(series['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9))),
      ]),
    ),
    Positioned(top: 4, right: 4, child: GestureDetector(
      onTap: () => _confirmDelete(context),
      child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.close, color: AdminTheme.red, size: 14)))),
    Positioned(top: 4, left: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
      child: const Text('SERIE', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)))),
  ]);

  void _confirmDelete(BuildContext context) => showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('¿Eliminar serie?', style: TextStyle(color: Colors.white)),
    content: Text(series['title'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: () async { await AdminApi.deleteSeries(series['_id'] ?? series['id']); Navigator.pop(ctx); onDelete(); },
        child: const Text('ELIMINAR', style: TextStyle(color: AdminTheme.red, fontWeight: FontWeight.bold))),
    ],
  ));
}

class _AddSeriesDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddSeriesDialog({required this.onAdded});
  @override State<_AddSeriesDialog> createState() => _AddSeriesState();
}

class _AddSeriesState extends State<_AddSeriesDialog> {
  final _title = TextEditingController();
  final _poster = TextEditingController();
  final _year = TextEditingController();
  final _rating = TextEditingController();
  final _genre = TextEditingController();
  final _desc = TextEditingController();
  bool _featured = false, _loading = false;
  String? _error;

  Future<void> _add() async {
    if (_title.text.isEmpty) { setState(() => _error = 'Título requerido'); return; }
    setState(() { _loading = true; _error = null; });
    final r = await AdminApi.addSeries({
      'title': _title.text.trim(), 'poster': _poster.text.trim(),
      'year': _year.text.trim(), 'rating': _rating.text.trim(),
      'genre': _genre.text.trim(), 'description': _desc.text.trim(),
      'featured': _featured,
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
      _field(_title, 'Título *'),
      _field(_poster, 'URL del poster'),
      Row(children: [
        Expanded(child: _field(_year, 'Año')),
        const SizedBox(width: 8),
        Expanded(child: _field(_rating, 'Rating')),
      ]),
      _field(_genre, 'Género'),
      _field(_desc, 'Descripción', maxLines: 2),
      Row(children: [
        Checkbox(value: _featured, onChanged: (v) => setState(() => _featured = v!), activeColor: AdminTheme.gold),
        const Text('Destacada', style: TextStyle(color: Colors.white)),
      ]),
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

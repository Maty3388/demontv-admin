import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});
  @override State<MoviesScreen> createState() => _State();
}

class _State extends State<MoviesScreen> {
  List _movies = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await AdminApi.getMovies();
      setState(() => _movies = r['movies'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      title: Text('Películas (${_movies.length})'),
      actions: [
        IconButton(icon: const Icon(Icons.add_circle_outline, color: AdminTheme.cyan), onPressed: _showAdd),
        IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.cyan), onPressed: _load),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
      : _movies.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.movie_outlined, color: AdminTheme.textHint, size: 60),
            const SizedBox(height: 12),
            const Text('Sin películas', style: TextStyle(color: AdminTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _showAdd, style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.cyan), child: const Text('Agregar', style: TextStyle(color: Colors.black))),
          ]))
        : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.6),
            itemCount: _movies.length,
            itemBuilder: (ctx, i) => _MovieCard(movie: _movies[i], onDelete: _load),
          ),
  );

  void _showAdd() => showDialog(context: context, builder: (_) => _AddMovieDialog(onAdded: _load));
}

class _MovieCard extends StatelessWidget {
  final Map movie;
  final VoidCallback onDelete;
  const _MovieCard({required this.movie, required this.onDelete});

  @override
  Widget build(BuildContext context) => Stack(children: [
    Container(
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: movie['poster']?.isNotEmpty == true
            ? Image.network(movie['poster'], fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const Icon(Icons.movie, color: AdminTheme.textHint, size: 40))
            : const Center(child: Icon(Icons.movie, color: AdminTheme.textHint, size: 40)))),
        Padding(padding: const EdgeInsets.all(4),
          child: Text(movie['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9))),
      ]),
    ),
    Positioned(top: 4, right: 4, child: GestureDetector(
      onTap: () => _confirmDelete(context),
      child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.close, color: AdminTheme.red, size: 14)),
    )),
    if (movie['featured'] == true)
      Positioned(top: 4, left: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(color: AdminTheme.gold.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
        child: const Text('★', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)))),
  ]);

  void _confirmDelete(BuildContext context) => showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('¿Eliminar película?', style: TextStyle(color: Colors.white)),
    content: Text(movie['title'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: () async { await AdminApi.deleteMovie(movie['id']); Navigator.pop(ctx); onDelete(); },
        child: const Text('ELIMINAR', style: TextStyle(color: AdminTheme.red, fontWeight: FontWeight.bold))),
    ],
  ));
}

class _AddMovieDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddMovieDialog({required this.onAdded});
  @override State<_AddMovieDialog> createState() => _AddMovieState();
}

class _AddMovieState extends State<_AddMovieDialog> {
  final _title = TextEditingController();
  final _poster = TextEditingController();
  final _year = TextEditingController();
  final _rating = TextEditingController();
  final _genre = TextEditingController();
  final _desc = TextEditingController();
  final _url = TextEditingController();
  bool _featured = false, _loading = false;
  String? _error;

  Future<void> _add() async {
    if (_title.text.isEmpty) { setState(() => _error = 'Título requerido'); return; }
    setState(() { _loading = true; _error = null; });
    final r = await AdminApi.addMovie({
      'title': _title.text.trim(), 'poster': _poster.text.trim(),
      'year': _year.text.trim(), 'rating': _rating.text.trim(),
      'genre': _genre.text.trim(), 'description': _desc.text.trim(),
      'stream_url': _url.text.trim(), 'featured': _featured,
    });
    setState(() => _loading = false);
    if (r['success'] == true) { widget.onAdded(); Navigator.pop(context); }
    else setState(() => _error = r['error'] ?? 'Error');
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Agregar Película', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_title, 'Título *'),
      _field(_poster, 'URL del poster'),
      _field(_url, 'URL del stream (opcional)'),
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

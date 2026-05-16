import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class ImportM3uScreen extends StatefulWidget {
  final VoidCallback onImported;
  const ImportM3uScreen({super.key, required this.onImported});
  @override State<ImportM3uScreen> createState() => _State();
}

class _State extends State<ImportM3uScreen> {
  final _urlCtrl  = TextEditingController();
  final _textCtrl = TextEditingController();
  bool _loading = false, _useText = false, _verifyDone = false;
  List<_Ch> _parsed = [], _selected = [];
  int _verifying = 0, _verified = 0;
  String? _error;

  List<_Ch> _parseM3u(String content) {
    final list = <_Ch>[];
    final lines = content.split('\n').map((l) => l.trim()).toList();
    String? name, logo, cat;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('#EXTINF')) {
        name = RegExp(r'tvg-name="([^"]*)"').firstMatch(line)?.group(1);
        logo = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line)?.group(1) ?? '';
        cat  = RegExp(r'group-title="([^"]*)"').firstMatch(line)?.group(1) ?? 'General';
        if (name == null || name.isEmpty) {
          final idx = line.lastIndexOf(',');
          if (idx != -1) name = line.substring(idx + 1).trim();
        }
      } else if (!line.startsWith('#') && line.isNotEmpty && name != null) {
        list.add(_Ch(name: name, logo: logo ?? '', cat: cat ?? 'General', url: line));
        name = null;
      }
    }
    return list;
  }

  Future<void> _loadUrl() async {
    if (_urlCtrl.text.isEmpty) { setState(() => _error = 'Ingresá la URL'); return; }
    setState(() { _loading = true; _error = null; _parsed = []; _verifyDone = false; });
    try {
      final r = await AdminApi.fetchM3u(_urlCtrl.text.trim());
      if (r['content'] != null) {
        final p = _parseM3u(r['content']);
        setState(() { _parsed = p; _selected = List.from(p); });
      } else setState(() => _error = r['error'] ?? 'Error');
    } catch (e) { setState(() => _error = 'Error: $e'); }
    setState(() => _loading = false);
  }

  void _loadText() {
    if (_textCtrl.text.isEmpty) { setState(() => _error = 'Pegá el contenido M3U'); return; }
    final p = _parseM3u(_textCtrl.text);
    if (p.isEmpty) { setState(() => _error = 'No se encontraron canales'); return; }
    setState(() { _parsed = p; _selected = List.from(p); _error = null; _verifyDone = false; });
  }

  Future<void> _verifyAll() async {
    if (_selected.isEmpty) return;
    setState(() { _verifying = _selected.length; _verified = 0; _verifyDone = false; });
    final results = <_Ch>[];
    for (final ch in _selected) {
      try {
        final r = await AdminApi.verifyStream(ch.url);
        results.add(ch.copyWith(active: r['ok'] == true));
      } catch (_) { results.add(ch.copyWith(active: false)); }
      setState(() => _verified++);
    }
    setState(() { _selected = results; _verifyDone = true; });
  }

  Future<void> _import() async {
    final list = _verifyDone ? _selected.where((c) => c.active == true).toList() : _selected;
    if (list.isEmpty) { setState(() => _error = 'Sin canales para importar'); return; }
    setState(() { _loading = true; _error = null; });
    int ok = 0, fail = 0;
    for (final ch in list) {
      try {
        final r = await AdminApi.addChannel(ch.name, ch.cat, ch.logo, ch.url);
        if (r['success'] == true) ok++; else fail++;
      } catch (_) { fail++; }
    }
    setState(() => _loading = false);
    widget.onImported();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ $ok importados${fail > 0 ? ", $fail fallaron (duplicados o error)" : ""}'),
      backgroundColor: AdminTheme.cyan, duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(title: const Text('Importar Playlist M3U')),
    body: Column(children: [
      Row(children: [
        Expanded(child: GestureDetector(onTap: () => setState(() => _useText = false),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 12), color: AdminTheme.surface,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: !_useText ? AdminTheme.cyan : Colors.transparent, width: 2))),
            child: Text('Desde URL', textAlign: TextAlign.center, style: TextStyle(color: !_useText ? AdminTheme.cyan : AdminTheme.textSecondary, fontWeight: FontWeight.bold))))),
        Expanded(child: GestureDetector(onTap: () => setState(() => _useText = true),
          child: Container(padding: const EdgeInsets.symmetric(vertical: 12), color: AdminTheme.surface,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _useText ? AdminTheme.cyan : Colors.transparent, width: 2))),
            child: Text('Pegar texto', textAlign: TextAlign.center, style: TextStyle(color: _useText ? AdminTheme.cyan : AdminTheme.textSecondary, fontWeight: FontWeight.bold))))),
      ]),
      Expanded(child: _parsed.isEmpty ? _buildInput() : _buildResults()),
    ]),
  );

  Widget _buildInput() => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
    if (!_useText) ...[
      TextField(controller: _urlCtrl, style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'http://ejemplo.com/lista.m3u', prefixIcon: Icon(Icons.link))),
      const SizedBox(height: 16),
      _Btn(label: _loading ? 'Cargando...' : 'Cargar Playlist', onTap: _loading ? null : _loadUrl, color: AdminTheme.cyan),
    ] else ...[
      TextField(controller: _textCtrl, maxLines: 10, style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: const InputDecoration(hintText: '#EXTM3U\n#EXTINF:-1 tvg-name="Canal",Canal\nhttp://stream.url')),
      const SizedBox(height: 16),
      _Btn(label: 'Analizar M3U', onTap: _loadText, color: AdminTheme.cyan),
    ],
    if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: AdminTheme.red))],
  ]));

  Widget _buildResults() => Column(children: [
    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), color: AdminTheme.surface,
      child: Row(children: [
        Text('${_parsed.length} canales encontrados', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (_verifyDone) ...[
          Text('✅ ${_selected.where((c) => c.active == true).length}', style: const TextStyle(color: Colors.green, fontSize: 13)),
          const SizedBox(width: 8),
          Text('❌ ${_selected.where((c) => c.active == false).length}', style: const TextStyle(color: AdminTheme.red, fontSize: 13)),
        ],
      ])),
    if (_verifying > 0 && !_verifyDone)
      LinearProgressIndicator(value: _verified / _verifying, backgroundColor: AdminTheme.surfaceAlt, color: AdminTheme.cyan),
    Expanded(child: ListView.builder(
      itemCount: _selected.length,
      itemBuilder: (ctx, i) {
        final ch = _selected[i];
        return ListTile(dense: true,
          leading: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle,
            color: ch.active == true ? Colors.green : ch.active == false ? AdminTheme.red : AdminTheme.textHint)),
          title: Text(ch.name, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(ch.cat, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 10)));
      })),
    Container(padding: const EdgeInsets.all(12), color: AdminTheme.surface, child: Column(children: [
      if (_verifying > 0 && !_verifyDone)
        Text('Verificando $_verified de $_verifying...', style: const TextStyle(color: AdminTheme.cyan, fontSize: 12)),
      if (!_verifyDone) ...[
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _Btn(label: _verifying > 0 ? 'Verificando...' : 'Verificar Todos', onTap: _verifying > 0 ? null : _verifyAll, color: AdminTheme.gold)),
          const SizedBox(width: 8),
          Expanded(child: _Btn(label: 'Importar Todo', onTap: _loading ? null : _import, color: AdminTheme.cyan)),
        ]),
      ] else ...[
        Text('${_selected.where((c) => c.active == true).length} activos listos para importar', style: const TextStyle(color: Colors.green, fontSize: 12)),
        const SizedBox(height: 8),
        _Btn(label: _loading ? 'Importando...' : 'Importar Activos', onTap: _loading ? null : _import, color: Colors.green),
      ],
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 12))],
    ])),
  ]);
}

class _Btn extends StatelessWidget {
  final String label; final VoidCallback? onTap; final Color color;
  const _Btn({required this.label, required this.onTap, required this.color});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(height: 44, width: double.infinity,
      decoration: BoxDecoration(color: onTap != null ? color : AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(label, style: TextStyle(color: onTap != null ? Colors.black : AdminTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)))));
}

class _Ch {
  final String name, logo, cat, url;
  final bool? active;
  const _Ch({required this.name, required this.logo, required this.cat, required this.url, this.active});
  _Ch copyWith({bool? active}) => _Ch(name: name, logo: logo, cat: cat, url: url, active: active ?? this.active);
}

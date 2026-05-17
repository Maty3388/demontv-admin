import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class VersionScreen extends StatefulWidget {
  const VersionScreen({super.key});
  @override State<VersionScreen> createState() => _VersionState();
}

class _VersionState extends State<VersionScreen> {
  final _version   = TextEditingController();
  final _apkUrl    = TextEditingController();
  final _changelog = TextEditingController();
  bool _force = false, _loading = false;
  Map? _current;
  String? _msg;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await AdminApi.getAppVersion();
      setState(() {
        _current = r;
        _version.text   = r['version'] ?? '';
        _apkUrl.text    = r['apkUrl'] ?? '';
        _changelog.text = r['changelog'] ?? '';
        _force = r['forceUpdate'] == true;
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_version.text.isEmpty || _apkUrl.text.isEmpty) {
      setState(() => _msg = 'Version y URL del APK son requeridos');
      return;
    }
    setState(() { _loading = true; _msg = null; });
    try {
      final r = await AdminApi.updateAppVersion(
        version: _version.text.trim(),
        apkUrl: _apkUrl.text.trim(),
        changelog: _changelog.text.trim(),
        forceUpdate: _force,
      );
      if (r['success'] == true) {
        setState(() => _msg = 'Actualizacion publicada!');
        _load();
      } else {
        setState(() => _msg = r['error'] ?? 'Error');
      }
    } catch (e) {
      setState(() => _msg = 'Error: \$e');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(title: const Text('Control de Actualizaciones')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_current != null) Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.info_outline, color: AdminTheme.cyan, size: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Version en produccion', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
            Text(_current!['version'] ?? '', style: const TextStyle(color: AdminTheme.cyan, fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (_current!['forceUpdate'] == true ? AdminTheme.red : Colors.green).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8)),
            child: Text(
              _current!['forceUpdate'] == true ? 'FORZADA' : 'OPCIONAL',
              style: TextStyle(color: _current!['forceUpdate'] == true ? AdminTheme.red : Colors.green, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('Publicar nueva actualizacion', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      _field(_version, 'Nueva version (ej: 1.1.0)', Icons.tag),
      const SizedBox(height: 12),
      _field(_apkUrl, 'URL directa del APK', Icons.link),
      const SizedBox(height: 4),
      const Text('Subi el APK y pega la URL de descarga directa', style: TextStyle(color: AdminTheme.textHint, fontSize: 11)),
      const SizedBox(height: 12),
      _field(_changelog, 'Novedades / Changelog', Icons.notes, maxLines: 4),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.warning_amber, color: AdminTheme.red, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Actualizacion forzada', style: TextStyle(color: Colors.white, fontSize: 14)),
            Text('Los clientes no pueden ignorarla', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
          ])),
          Switch(value: _force, onChanged: (v) => setState(() => _force = v), activeColor: AdminTheme.red),
        ]),
      ),
      const SizedBox(height: 24),
      if (_msg != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _msg!.contains('!') ? Colors.green.withOpacity(0.15) : AdminTheme.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(_msg!.contains('!') ? Icons.check_circle : Icons.error,
              color: _msg!.contains('!') ? Colors.green : AdminTheme.red, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_msg!, style: TextStyle(color: _msg!.contains('!') ? Colors.green : AdminTheme.red, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 16),
      ],
      GestureDetector(
        onTap: _loading ? null : _save,
        child: Container(height: 52, width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _loading ? [AdminTheme.surfaceAlt, AdminTheme.surface] : [const Color(0xFF00BFFF), const Color(0xFFFFD700)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(26)),
          child: Center(child: _loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
            : const Text('Publicar Actualizacion', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16))),
        ),
      ),
      const SizedBox(height: 32),
    ])),
  );

  Widget _field(TextEditingController c, String hint, IconData icon, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: TextField(
      controller: c, maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AdminTheme.textSecondary, size: 20),
        hintText: hint,
        filled: true, fillColor: AdminTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))));
}

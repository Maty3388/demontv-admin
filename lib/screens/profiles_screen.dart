import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class ProfilesDialog extends StatefulWidget {
  final Map client;
  final VoidCallback onDone;
  const ProfilesDialog({required this.client, required this.onDone, super.key});
  @override State<ProfilesDialog> createState() => _ProfilesDialogState();
}

class _ProfilesDialogState extends State<ProfilesDialog> {
  List _profiles = [];
  bool _loading = true;

  String get _clientId => (widget.client['id'] ?? widget.client['_id'] ?? '').toString();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await AdminApi.getClientProfiles(_clientId);
      setState(() => _profiles = r['profiles'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _editProfile(Map prof) async {
    final nameCtrl = TextEditingController(text: prof['name'] ?? '');
    final avatarCtrl = TextEditingController(text: prof['avatar'] ?? '');
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminTheme.surface,
      title: Text('Editar ${prof['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Nombre del perfil', prefixIcon: Icon(Icons.person_outline, size: 18))),
        const SizedBox(height: 12),
        TextField(controller: avatarCtrl, style: const TextStyle(color: Colors.white, fontSize: 22),
          decoration: const InputDecoration(hintText: 'Avatar (emoji)', prefixIcon: Icon(Icons.face, size: 18))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR', style: TextStyle(color: AdminTheme.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('GUARDAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
      ],
    ));
    if (confirmed != true) return;
    await AdminApi.updateClientProfile(_clientId, prof['id'], name: nameCtrl.text.trim(), avatar: avatarCtrl.text.trim());
    _load();
  }

  Future<void> _unlinkDevice(Map prof) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminTheme.surface,
      title: const Text('Desvincular dispositivo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text('¿Desvincular el dispositivo de ${prof['name']}?', style: const TextStyle(color: AdminTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR', style: TextStyle(color: AdminTheme.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DESVINCULAR', style: TextStyle(color: AdminTheme.red, fontWeight: FontWeight.bold))),
      ],
    ));
    if (confirmed != true) return;
    await AdminApi.unlinkProfileDevice(_clientId, prof['id']);
    _load();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Perfiles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      Text(widget.client['email'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
    ]),
    content: SizedBox(
      width: double.maxFinite,
      child: _loading
        ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
        : _profiles.isEmpty
          ? const Text('Sin perfiles', style: TextStyle(color: AdminTheme.textSecondary))
          : Column(mainAxisSize: MainAxisSize.min, children: _profiles.map((p) {
              final hasDevice = p['device_id'] != null && p['device_id'].toString().isNotEmpty;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Text(p['avatar'] ?? '👤', style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Row(children: [
                      Container(width: 7, height: 7, margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: hasDevice ? Colors.green : AdminTheme.textHint)),
                      Text(hasDevice ? 'Dispositivo vinculado' : 'Sin dispositivo',
                        style: TextStyle(color: hasDevice ? Colors.green : AdminTheme.textHint, fontSize: 11)),
                    ]),
                  ])),
                  IconButton(icon: const Icon(Icons.edit_outlined, color: AdminTheme.gold, size: 20), onPressed: () => _editProfile(p)),
                  if (hasDevice)
                    IconButton(icon: const Icon(Icons.phone_android, color: AdminTheme.red, size: 20), onPressed: () => _unlinkDevice(p),
                      tooltip: 'Desvincular dispositivo'),
                ]),
              );
            }).toList()),
    ),
    actions: [
      TextButton(onPressed: () { widget.onDone(); Navigator.pop(context); },
        child: const Text('CERRAR', style: TextStyle(color: AdminTheme.textSecondary))),
    ],
  );
}

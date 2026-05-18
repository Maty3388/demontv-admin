import "package:flutter/material.dart";
import "package:file_picker/file_picker.dart";
import "../services/api.dart";
import "../theme/theme.dart";
import "import_m3u_screen.dart";

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
      setState(() => _channels = r["channels"] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showAdd() => showDialog(context: context, builder: (_) => _AddChannelDialog(onAdded: _load));

  void _showImportOptions() {
    showModalBottomSheet(context: context, backgroundColor: AdminTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Importar Playlist", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListTile(leading: const Icon(Icons.link, color: AdminTheme.cyan),
          title: const Text("Desde URL", style: TextStyle(color: Colors.white)),
          subtitle: const Text("http://ejemplo.com/lista.m3u", style: TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
          onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => ImportM3uScreen(onImported: _load))); }),
        ListTile(leading: const Icon(Icons.folder_open, color: AdminTheme.gold),
          title: const Text("Desde archivo local", style: TextStyle(color: Colors.white)),
          subtitle: const Text(".m3u, .m3u8, .txt", style: TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
          onTap: () async {
            Navigator.pop(ctx);
            try {
              final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
              if (result != null && result.files.single.bytes != null) {
                final content = String.fromCharCodes(result.files.single.bytes!);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ImportM3uScreen(onImported: _load, fileContent: content)));
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AdminTheme.red));
            }
          }),
        ListTile(leading: const Icon(Icons.text_snippet_outlined, color: Colors.purple),
          title: const Text("Pegar texto M3U", style: TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => ImportM3uScreen(onImported: _load, pasteMode: true))); }),
      ])));
  }

  Future<void> _deleteChannel(String id, String name) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminTheme.surface,
      title: const Text("Eliminar canal?", style: TextStyle(color: Colors.white)),
      content: Text(name, style: const TextStyle(color: AdminTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: AdminTheme.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ELIMINAR", style: TextStyle(color: AdminTheme.red, fontWeight: FontWeight.bold))),
      ],
    ));
    if (confirm == true) {
      final r = await AdminApi.deleteChannel(id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Respuesta: ${r.toString()}"), duration: const Duration(seconds: 4)));
      if (r["success"] == true) { _load(); }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      title: Text("Canales (${_channels.length})"),
      actions: [
        IconButton(icon: const Icon(Icons.playlist_add, color: AdminTheme.gold), onPressed: _showImportOptions),
        IconButton(icon: const Icon(Icons.add_circle_outline, color: AdminTheme.cyan), onPressed: _showAdd),
        IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.cyan), onPressed: _load),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: AdminTheme.cyan))
      : _channels.isEmpty
        ? const Center(child: Text("Sin canales", style: TextStyle(color: AdminTheme.textSecondary)))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _channels.length,
            itemBuilder: (ctx, i) {
              final ch = _channels[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminTheme.border, width: 0.5)),
                child: Row(children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                    child: ch["logo"]?.isNotEmpty == true
                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ch["logo"], fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: AdminTheme.textHint, size: 20)))
                      : const Icon(Icons.tv, color: AdminTheme.textHint, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ch["name"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(ch["category"] ?? "", style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
                  ])),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.delete_outline, color: AdminTheme.red, size: 20), onPressed: () { final raw = (ch["_id"] ?? ch["id"] ?? "").toString(); final id = raw.replaceAll("ObjectId(", "").replaceAll(")", "").replaceAll("'", "").trim(); _deleteChannel(id, ch["name"] ?? ""); }),
                    IconButton(icon: const Icon(Icons.edit_outlined, color: AdminTheme.cyan, size: 20), onPressed: () { final raw = (ch["_id"] ?? ch["id"] ?? "").toString(); final id = raw.replaceAll("ObjectId(", "").replaceAll(")", "").replaceAll("'", "").trim(); showDialog(context: context, builder: (_) => _EditChannelDialog(id: id, channel: ch, onEdited: _load)); }),
                  ]),
                  ]),
                ]),
              );
              );
            },
          ),
        );
      },
    );
  }
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
    if (_url.text.isEmpty) { setState(() => _error = "URL requerida"); return; }
    setState(() { _verifying = true; _error = null; _verifyResult = null; });
    final r = await AdminApi.verifyStream(_url.text.trim());
    setState(() { _verifyResult = r; _verifying = false; });
    if (r["ok"] != true) setState(() => _error = "Stream no responde");
  }

  Future<void> _add() async {
    if (_name.text.isEmpty || _url.text.isEmpty) { setState(() => _error = "Nombre y URL requeridos"); return; }
    setState(() { _adding = true; _error = null; });
    final r = await AdminApi.addChannel(_name.text.trim(), _cat.text.trim().isNotEmpty ? _cat.text.trim() : "General", _logo.text.trim(), _url.text.trim());
    setState(() => _adding = false);
    if (r["success"] == true) { widget.onAdded(); Navigator.pop(context); }
    else setState(() => _error = r["error"] ?? "Error");
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text("Agregar Canal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _f(_name, "Nombre *"), _f(_cat, "Categoria"), _f(_logo, "URL logo"), _f(_url, "URL stream *"),
      const SizedBox(height: 10),
      GestureDetector(onTap: _verifying ? null : _verify,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_verifying) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan)),
            const SizedBox(width: 6),
          ]))),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: _adding ? null : _add,
        child: _adding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
            : const Text("AGREGAR", style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );

  Widget _f(TextEditingController c, String h) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(hintText: h, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))));
}

class _EditChannelDialog extends StatefulWidget {
  final String id;
  final Map channel;
  final VoidCallback onEdited;
  const _EditChannelDialog({required this.id, required this.channel, required this.onEdited});
  @override State<_EditChannelDialog> createState() => _EditState();
}

class _EditState extends State<_EditChannelDialog> {
  late final _name = TextEditingController(text: widget.channel["name"] ?? "");
  late final _cat  = TextEditingController(text: widget.channel["category"] ?? "");
  late final _logo = TextEditingController(text: widget.channel["logo"] ?? "");
  late final _url  = TextEditingController(text: widget.channel["stream_url"] ?? "");
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_name.text.isEmpty || _url.text.isEmpty) { setState(() => _error = "Nombre y URL requeridos"); return; }
    setState(() { _saving = true; _error = null; });
    final r = await AdminApi.updateChannel(widget.id, _name.text.trim(), _cat.text.trim().isNotEmpty ? _cat.text.trim() : "General", _logo.text.trim(), _url.text.trim());
    setState(() => _saving = false);
    if (r["success"] == true) { widget.onEdited(); Navigator.pop(context); }
    else setState(() => _error = r["error"] ?? "Error al guardar");
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text("Editar Canal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _f(_name, "Nombre *"),
      _f(_cat, "Categoria"),
      _f(_logo, "URL logo"),
      _f(_url, "URL stream *"),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8),
        child: Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 12))),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(onPressed: _saving ? null : _save,
        child: _saving
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
          : const Text("GUARDAR", style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );

  Widget _f(TextEditingController c, String h) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(hintText: h, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8))));
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class ResellersScreen extends StatefulWidget {
  const ResellersScreen({super.key});
  @override State<ResellersScreen> createState() => _State();
}

class _State extends State<ResellersScreen> {
  List _resellers = [];
  bool _loading = true;
  String _msg = '';
  bool _msgOk = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await AdminApi.getResellers();
      setState(() => _resellers = r['resellers'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showMsg(String msg, bool ok) => setState(() { _msg = msg; _msgOk = ok; });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      backgroundColor: AdminTheme.surface,
      title: Text('Resellers (${_resellers.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.add, color: AdminTheme.cyan), onPressed: () async {
          await showDialog(context: context, builder: (_) => _CreateResellerDialog(onCreated: _load));
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
        : _resellers.isEmpty
          ? const Center(child: Text('Sin resellers', style: TextStyle(color: AdminTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _resellers.length,
              itemBuilder: (ctx, i) {
                final r = _resellers[i];
                final id = (r['_id'] ?? r['id'] ?? '').toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AdminTheme.border, width: 0.5)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7B2FFF), Color(0xFF00BFFF)]), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.store, color: Colors.white, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r['email'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('ID: ${((r["_id"] ?? r["id"] ?? "") as String).length > 8 ? ((r["_id"] ?? r["id"] ?? "") as String).substring(0,8)+"..." : (r["_id"] ?? r["id"] ?? "")}', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AdminTheme.cyan.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(r['rank'] ?? 'basic', style: const TextStyle(color: AdminTheme.cyan, fontSize: 11, fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _InfoChip(Icons.account_balance_wallet, 'Balance: ${r['balance'] ?? 0}', AdminTheme.gold),
                      const SizedBox(width: 8),
                      _InfoChip(Icons.stars, 'Extras: ${r['extras'] ?? 0}', Colors.purple),
                      const SizedBox(width: 8),
                      _InfoChip(Icons.casino, 'Giros: ${r['spins'] ?? 0}', Colors.green),
                    ]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton.icon(
                        onPressed: () => showDialog(context: context, builder: (_) => _RechargeDialog(id: id, email: r['email'] ?? '', onDone: _load)),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Recargar'),
                        style: TextButton.styleFrom(foregroundColor: AdminTheme.cyan)),
                      TextButton.icon(
                        onPressed: () => showDialog(context: context, builder: (_) => _EditResellerDialog(id: id, email: r['email'] ?? '', onDone: _load)),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                        style: TextButton.styleFrom(foregroundColor: Colors.purple)),
                      TextButton.icon(
                        onPressed: () => showDialog(context: context, builder: (_) => _RankDialog(id: id, email: r['email'] ?? '', currentRank: r['rank'] ?? 'Bronce', onDone: _load)),
                        icon: const Icon(Icons.military_tech_outlined, size: 16),
                        label: const Text('Rango'),
                        style: TextButton.styleFrom(foregroundColor: AdminTheme.gold)),
                      TextButton.icon(
                        onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                          backgroundColor: AdminTheme.surface,
                          title: const Text('Eliminar reseller', style: TextStyle(color: Colors.white)),
                          content: Text('¿Eliminar ${r['email']}?', style: const TextStyle(color: AdminTheme.textSecondary)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
                            TextButton(onPressed: () async {
                              Navigator.pop(ctx);
                              await AdminApi.deleteReseller(id);
                              _load();
                              _showMsg('Reseller eliminado', true);
                            }, child: const Text('Eliminar', style: TextStyle(color: AdminTheme.red, fontWeight: FontWeight.bold))),
                          ])),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(foregroundColor: AdminTheme.red)),
                    ]),
                  ]),
                );
              })),
    ]),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]));
}

class _CreateResellerDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateResellerDialog({required this.onCreated});
  @override State<_CreateResellerDialog> createState() => _CreateResellerState();
}

class _CreateResellerState extends State<_CreateResellerDialog> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  String _rank = 'Bronce';
  final _balanceCtrl = TextEditingController(text: '0');
  bool _loading = false;
  String? _error;

  static const _ranks = ['Bronce', 'Plata', 'Oro', 'Diamante'];
  static const _rankIcons = {'Bronce': '🥉', 'Plata': '🥈', 'Oro': '🥇', 'Diamante': '💎'};
  static const _rankColors = {'Bronce': Color(0xFFC9A84C), 'Plata': Color(0xFFB0BEC5), 'Oro': Color(0xFFFFD700), 'Diamante': Color(0xFF00E5FF)};

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF0F0F1A),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Crear Reseller', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white54)),
      ]),
      const SizedBox(height: 20),
      // Email
      Container(
        decoration: BoxDecoration(color: const Color(0xFF16162A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2A4A))),
        child: TextField(controller: _email, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Correo electrónico', hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.email_outlined, color: Colors.white38, size: 20), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14))),
      ),
      const SizedBox(height: 12),
      // Contraseña
      Container(
        decoration: BoxDecoration(color: const Color(0xFF16162A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2A4A))),
        child: TextField(controller: _pass, obscureText: true, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Contraseña', hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.white38, size: 20), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14))),
      ),
      const SizedBox(height: 20),
      // Rango
      const Text('Selecciona una categoría', style: TextStyle(color: Colors.white60, fontSize: 13)),
      const SizedBox(height: 10),
      Row(children: _ranks.map((r) {
        final sel = _rank == r;
        final color = _rankColors[r]!;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _rank = r),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? color.withOpacity(0.15) : const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? color : const Color(0xFF2A2A4A), width: sel ? 1.5 : 1),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_rankIcons[r]!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(r, style: TextStyle(color: sel ? color : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
        ));
      }).toList()),
      const SizedBox(height: 20),
      // Balance field
      const Text('Agregar balance', style: TextStyle(color: Colors.white60, fontSize: 13)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: const Color(0xFF16162A), borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminTheme.gold.withOpacity(0.4))),
        child: TextField(
          controller: _balanceCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AdminTheme.gold, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '0', hintStyle: TextStyle(color: Colors.white30),
            prefixIcon: Icon(Icons.monetization_on_outlined, color: AdminTheme.gold, size: 20),
            border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
      const SizedBox(height: 8),
      const Row(children: [
        Icon(Icons.info_outline, color: Colors.white30, size: 14),
        SizedBox(width: 6),
        Expanded(child: Text('Una vez creado no se puede revertir el rango sin acceso admin.', style: TextStyle(color: Colors.white30, fontSize: 11))),
      ]),
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 12))],
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: Color(0xFF2A2A4A)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('CANCELAR'),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: _loading ? null : () async {
            if (_email.text.isEmpty || _pass.text.isEmpty) { setState(() => _error = 'Completá los campos'); return; }
            setState(() { _loading = true; _error = null; });
            final r = await AdminApi.createReseller(_email.text.trim(), _pass.text.trim(), rank: _rank, balance: int.tryParse(_balanceCtrl.text.trim()) ?? 0);
            setState(() => _loading = false);
            if (r['success'] == true) {
              widget.onCreated();
              await Clipboard.setData(ClipboardData(text: 'Email: \${_email.text.trim()}\nContraseña: \${_pass.text.trim()}\nRango: \$_rank\nBalance: \${int.tryParse(_balanceCtrl.text.trim()) ?? 0}'));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Credenciales copiadas al portapapeles'), backgroundColor: Colors.green));
            }
            else setState(() => _error = r['error'] ?? 'Error');
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('GENERAR', style: TextStyle(fontWeight: FontWeight.bold)),
        )),
      ]),
    ])),
  );
}

class _RechargeDialog extends StatefulWidget {
  final String id, email;
  final VoidCallback onDone;
  const _RechargeDialog({required this.id, required this.email, required this.onDone});
  @override State<_RechargeDialog> createState() => _RechargeState();
}

class _RechargeState extends State<_RechargeDialog> {
  final _amountCtrl = TextEditingController(text: '10');
  bool _loading = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Recargar balance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(widget.email, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminTheme.gold.withOpacity(0.4))),
        child: TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AdminTheme.gold, fontSize: 28, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '0', hintStyle: TextStyle(color: Colors.white30),
            prefixIcon: Icon(Icons.monetization_on_outlined, color: AdminTheme.gold, size: 20),
            border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(
        onPressed: _loading ? null : () async {
          setState(() => _loading = true);
          await AdminApi.rechargeReseller(widget.id, int.tryParse(_amountCtrl.text.trim()) ?? 0);
          setState(() => _loading = false);
          widget.onDone();
          Navigator.pop(context);
        },
        child: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
          : const Text('RECARGAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );
}

class _RankDialog extends StatefulWidget {
  final String id, email, currentRank;
  final VoidCallback onDone;
  const _RankDialog({required this.id, required this.email, required this.currentRank, required this.onDone});
  @override State<_RankDialog> createState() => _RankDialogState();
}

class _RankDialogState extends State<_RankDialog> {
  late String _rank;
  bool _loading = false;

  static const _ranks = ['Bronce', 'Plata', 'Oro', 'Diamante'];
  static const _rankIcons = {'Bronce': '🥉', 'Plata': '🥈', 'Oro': '🥇', 'Diamante': '💎'};
  static const _rankColors = {'Bronce': Color(0xFFC9A84C), 'Plata': Color(0xFFB0BEC5), 'Oro': Color(0xFFFFD700), 'Diamante': Color(0xFF00E5FF)};

  @override
  void initState() { super.initState(); _rank = widget.currentRank; }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF0F0F1A),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        const Text('Cambiar Rango', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white54)),
      ]),
      const SizedBox(height: 8),
      Text(widget.email, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 20),
      Row(children: _ranks.map((r) {
        final sel = _rank == r;
        final color = _rankColors[r]!;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _rank = r),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? color.withOpacity(0.15) : const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? color : const Color(0xFF2A2A4A), width: sel ? 1.5 : 1),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_rankIcons[r]!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(r, style: TextStyle(color: sel ? color : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
        ));
      }).toList()),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: Color(0xFF2A2A4A)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('CANCELAR'),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            await AdminApi.setResellerRank(widget.id, _rank);
            setState(() => _loading = false);
            widget.onDone();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold)),
        )),
      ]),
    ])),
  );
}

class _EditResellerDialog extends StatefulWidget {
  final String id, email;
  final VoidCallback onDone;
  const _EditResellerDialog({required this.id, required this.email, required this.onDone});
  @override State<_EditResellerDialog> createState() => _EditResellerState();
}

class _EditResellerState extends State<_EditResellerDialog> {
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Editar Reseller', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(widget.email, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AdminTheme.border)),
        child: TextField(
          controller: _pass,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nueva contraseña',
            prefixIcon: Icon(Icons.lock_outline, color: AdminTheme.textSecondary, size: 20),
            border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 12))],
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(
        onPressed: _loading ? null : () async {
          if (_pass.text.isEmpty) { setState(() => _error = 'Ingresá la nueva contraseña'); return; }
          setState(() { _loading = true; _error = null; });
          final r = await AdminApi.editReseller(widget.id, password: _pass.text.trim());
          setState(() => _loading = false);
          if (r['success'] == true) {
            await Clipboard.setData(ClipboardData(text: 'Email: \${widget.email}\nContraseña: \${_pass.text.trim()}'));
            widget.onDone();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Contraseña actualizada y copiada'), backgroundColor: Colors.green));
          } else {
            setState(() => _error = r['error'] ?? 'Error');
          }
        },
        child: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
          : const Text('GUARDAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );
}

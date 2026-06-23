import 'package:flutter/material.dart';
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
                        Text('ID: ${r['userId'] ?? ''}', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
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
  final _pass = TextEditingController();
  final _balance = TextEditingController(text: '0');
  String _rank = 'Bronce';
  bool _loading = false;
  String? _error;

  static const _ranks = ['Bronce', 'Silver', 'Gold', 'Platinum'];
  static const _rankLabels = {'Bronce': '🥉 Bronce', 'Silver': '🥈 Silver', 'Gold': '🥇 Gold', 'Platinum': '💎 Platinum'};

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Crear Reseller', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _email, keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'Correo', prefixIcon: Icon(Icons.email_outlined, size: 18))),
      const SizedBox(height: 12),
      TextField(controller: _pass, obscureText: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline, size: 18))),
      const SizedBox(height: 12),
      TextField(controller: _balance, keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'Balance inicial', prefixIcon: Icon(Icons.monetization_on_outlined, size: 18))),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(8)),
        child: DropdownButton<String>(
          value: _rank,
          isExpanded: true,
          dropdownColor: AdminTheme.surfaceAlt,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: AdminTheme.textSecondary),
          items: _ranks.map((r) => DropdownMenuItem(value: r, child: Text(_rankLabels[r]!, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: (v) { if (v != null) setState(() => _rank = v); },
        ),
      ),
      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 12))],
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(
        onPressed: _loading ? null : () async {
          if (_email.text.isEmpty || _pass.text.isEmpty) { setState(() => _error = 'Completá los campos'); return; }
          setState(() { _loading = true; _error = null; });
          final bal = int.tryParse(_balance.text.trim()) ?? 0;
          final r = await AdminApi.createReseller(_email.text.trim(), _pass.text.trim(), rank: _rank, balance: bal);
          setState(() => _loading = false);
          if (r['success'] == true) { widget.onCreated(); Navigator.pop(context); }
          else setState(() => _error = r['error'] ?? 'Error');
        },
        child: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.cyan))
          : const Text('CREAR', style: TextStyle(color: AdminTheme.cyan, fontWeight: FontWeight.bold))),
    ],
  );
}

class _RechargeDialog extends StatefulWidget {
  final String id, email;
  final VoidCallback onDone;
  const _RechargeDialog({required this.id, required this.email, required this.onDone});
  @override State<_RechargeDialog> createState() => _RechargeState();
}

class _RechargeState extends State<_RechargeDialog> {
  int _amount = 10;
  bool _loading = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AdminTheme.surface,
    title: const Text('Recargar balance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(widget.email, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: () { if (_amount > 1) setState(() => _amount--); }, icon: const Icon(Icons.remove_circle_outline, color: AdminTheme.cyan)),
        Text('$_amount', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        IconButton(onPressed: () => setState(() => _amount++), icon: const Icon(Icons.add_circle_outline, color: AdminTheme.cyan)),
      ]),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AdminTheme.textSecondary))),
      TextButton(
        onPressed: _loading ? null : () async {
          setState(() => _loading = true);
          await AdminApi.rechargeReseller(widget.id, _amount);
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

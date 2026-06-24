import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override State<AdminLoginScreen> createState() => _State();
}

class _State extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await AdminApi.login(_email.text.trim(), _pass.text.trim());
      if (r['token'] != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _error = r['error'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      setState(() => _error = 'Sin conexión con el servidor');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(title: const Text('FluxTv Panel')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(children: [
          const SizedBox(height: 60),
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/logo.png', width: 72, height: 72, fit: BoxFit.cover),
            ),
            const SizedBox(width: 18),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bienvenido a', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 16)),
              Text('FluxTv Panel', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ]),
          ]),
          const SizedBox(height: 56),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.mail_outline, color: AdminTheme.textSecondary),
              hintText: 'Correo electrónico',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pass,
            obscureText: _obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: AdminTheme.textSecondary),
              hintText: 'Contraseña',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AdminTheme.textSecondary),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AdminTheme.red, fontSize: 13)),
          ],
          const Spacer(),
          GestureDetector(
            onTap: _loading ? null : _login,
            child: Container(
              height: 56, width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00BFFF), Color(0xFFFFD700)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(child: _loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                : const Text('Iniciar Sesión', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    ),
  );
}

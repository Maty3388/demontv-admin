import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/api.dart';
import '../theme/theme.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});
  @override State<AdminChatScreen> createState() => _ChatState();
}

class _ChatState extends State<AdminChatScreen> {
  io.Socket? _socket;
  final List<Map> _messages = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _connected = false;

  @override
  void initState() { super.initState(); _connect(); }

  void _connect() {
    _socket = io.io('http://149.104.92.205:25461', io.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());
    _socket!.onConnect((_) {
      setState(() => _connected = true);
      _socket!.emit('auth', AdminApi.token);
    });
    _socket!.on('pinned', (data) {
      if (data is Map) setState(() => _messages.insert(0, {...data, 'pinned': true}));
    });
    _socket!.on('history', (data) {
      if (data is List) { setState(() => _messages.addAll(data.cast<Map>())); _scrollBottom(); }
    });
    _socket!.on('message', (data) {
      if (data is Map) { setState(() => _messages.add(data)); _scrollBottom(); }
    });
    _socket!.onDisconnect((_) => setState(() => _connected = false));
    _socket!.connect();
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _socket!.emit('message', text);
    _ctrl.clear();
  }

  @override
  void dispose() { _socket?.disconnect(); _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Color _roleColor(String role) {
    if (role == 'admin') return AdminTheme.cyan;
    if (role == 'reseller') return AdminTheme.gold;
    if (role == 'system') return AdminTheme.textSecondary;
    return Colors.white70;
  }

  String _formatTime(String iso) {
    try {
      final t = DateTime.parse(iso).toLocal();
      return "${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}";
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.bg,
    appBar: AppBar(
      backgroundColor: AdminTheme.surface,
      title: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _connected ? Colors.green : AdminTheme.red)),
        const SizedBox(width: 8),
        Text(_connected ? 'Chat en Vivo' : 'Conectando...', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: AdminTheme.cyan), onPressed: () { _socket?.disconnect(); _connect(); }),
      ],
    ),
    body: Column(children: [
      Expanded(child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length,
        itemBuilder: (ctx, i) {
          final m = _messages[i];
          final isPinned = m['pinned'] == true;
          final role = m['role'] ?? 'user';
          final isMe = role == 'admin';
          if (isPinned) return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AdminTheme.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminTheme.gold.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.push_pin, color: AdminTheme.gold, size: 14), const SizedBox(width: 4), Text(m['user'] ?? '', style: const TextStyle(color: AdminTheme.gold, fontSize: 12, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 4),
              Text(m['text'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
            ]),
          );
          if (role == 'system') return Center(
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(m['text'] ?? '', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11))));
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isMe ? AdminTheme.cyan.withOpacity(0.2) : AdminTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMe ? AdminTheme.cyan.withOpacity(0.4) : AdminTheme.border)),
              child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                if (!isMe) Text(m['user'] ?? '', style: TextStyle(color: _roleColor(role), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(m['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 2),
                Text(_formatTime(m['time'] ?? ''), style: const TextStyle(color: AdminTheme.textHint, fontSize: 10)),
              ]),
            ),
          );
        },
      )),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(color: AdminTheme.surface, border: Border(top: BorderSide(color: AdminTheme.border))),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white),
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Escribí un mensaje...',
              hintStyle: const TextStyle(color: AdminTheme.textHint),
              filled: true, fillColor: AdminTheme.surfaceAlt,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            onSubmitted: (_) => _send(),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AdminTheme.cyan, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.black, size: 20)),
          ),
        ]),
      ),
    ]),
  );
}

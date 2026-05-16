import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminApi {
  static const base = 'http://149.104.92.205:25461';
  static String? token;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<Map<String, dynamic>> _post(String path, Map body) async {
    final r = await http.post(Uri.parse('$base$path'), headers: headers, body: jsonEncode(body));
    return jsonDecode(r.body);
  }
  static Future<Map<String, dynamic>> _get(String path) async {
    final r = await http.get(Uri.parse('$base$path'), headers: headers);
    return jsonDecode(r.body);
  }
  static Future<Map<String, dynamic>> _put(String path, Map body) async {
    final r = await http.put(Uri.parse('$base$path'), headers: headers, body: jsonEncode(body));
    return jsonDecode(r.body);
  }
  static Future<Map<String, dynamic>> _delete(String path) async {
    final r = await http.delete(Uri.parse('$base$path'), headers: headers);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> login(String email, String pass) async {
    final r = await _post('/admin/login', {'email': email, 'password': pass});
    if (r['token'] != null) token = r['token'];
    return r;
  }

  static Future<Map<String, dynamic>> getStats()   => _get('/admin/stats');
  static Future<Map<String, dynamic>> getProfile() => _get('/admin/profile');

  static Future<Map<String, dynamic>> getClients({String? filter, String? search}) {
    var url = '/admin/clients';
    final p = <String>[];
    if (filter != null && filter != 'todos') p.add('filter=$filter');
    if (search != null && search.isNotEmpty) p.add('search=${Uri.encodeComponent(search)}');
    if (p.isNotEmpty) url += '?${p.join("&")}';
    return _get(url);
  }

  static Future<Map<String, dynamic>> createClient(String email, String pass, int months, bool useExtras, {bool isDemo = false}) =>
      _post('/admin/clients', {'email': email, 'password': pass, 'months': months, 'useExtras': useExtras, 'isDemo': isDemo});
  static Future<Map<String, dynamic>> editClient(String id, {bool? blocked, String? password}) =>
      _put('/admin/clients/$id', {if (blocked != null) 'blocked': blocked, if (password != null) 'password': password});
  static Future<Map<String, dynamic>> deleteClient(String id) => _delete('/admin/clients/$id');
  static Future<Map<String, dynamic>> extendClient(String id, int months, bool useExtras) =>
      _post('/admin/clients/$id/extend', {'months': months, 'useExtras': useExtras});

  static Future<Map<String, dynamic>> getChannels() => _get('/admin/channels');
  static Future<Map<String, dynamic>> verifyStream(String url) => _post('/admin/channels/verify', {'url': url});
  static Future<Map<String, dynamic>> addChannel(String name, String cat, String logo, String url) =>
      _post('/admin/channels', {'name': name, 'category': cat, 'logo': logo, 'stream_url': url});
  static Future<Map<String, dynamic>> deleteChannel(String id) => _delete('/admin/channels/$id');

  static Future<Map<String, dynamic>> getMovies() => _get('/admin/movies');
  static Future<Map<String, dynamic>> addMovie(Map data) => _post('/admin/movies', data);
  static Future<Map<String, dynamic>> deleteMovie(String id) => _delete('/admin/movies/$id');

  static Future<Map<String, dynamic>> getSeries() => _get('/admin/series');
  static Future<Map<String, dynamic>> addSeries(Map data) => _post('/admin/series', data);
  static Future<Map<String, dynamic>> deleteSeries(String id) => _delete('/admin/series/$id');

  static Future<Map<String, dynamic>> getWatching() => _get('/admin/watching');
  static Future<Map<String, dynamic>> getLogs({String? type, int limit = 50}) {
    var url = '/admin/logs?limit=$limit';
    if (type != null) url += '&type=$type';
    return _get(url);
  }

  static Future<Map<String, dynamic>> spin() => _post('/admin/spin', {});
}

// Detectar si estamos en web via kIsWeb
import 'package:flutter/foundation.dart';

String getApiBase() {
  if (kIsWeb) return '';  // URL relativa - nginx hace proxy en /api/
  return 'http://149.104.92.205:25461';
}

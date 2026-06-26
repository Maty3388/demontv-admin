// Detectar si estamos en web via kIsWeb
import 'package:flutter/foundation.dart';

String getApiBase() {
  if (kIsWeb) return '';  // URL relativa - nginx hace proxy en /api/
  return 'http://31.40.212.209:25461';
}

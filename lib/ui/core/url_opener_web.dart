// Este arquivo só é usado no navegador (ver url_opener.dart).
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:web/web.dart' as web;

/// Abre o link em uma nova aba, sem dar acesso à página atual (`noopener`).
void openUrl(String url) {
  web.window.open(url, '_blank', 'noopener');
}

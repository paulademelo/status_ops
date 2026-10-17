// Este arquivo só é usado no navegador (ver theme_storage.dart).
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:web/web.dart' as web;

const _key = 'statusops.theme';

/// Tema salvo neste navegador (ou `null`).
String? readSavedTheme() {
  try {
    return web.window.localStorage.getItem(_key);
  } catch (_) {
    // Navegação privada ou armazenamento bloqueado: usa o padrão.
    return null;
  }
}

/// Lembra o tema escolhido neste navegador.
void saveTheme(String themeName) {
  try {
    web.window.localStorage.setItem(_key, themeName);
  } catch (_) {
    // Sem armazenamento: o tema vale só até recarregar a página.
  }
}

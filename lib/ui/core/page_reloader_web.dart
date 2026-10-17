// Este arquivo só é usado no navegador (ver page_reloader.dart).
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Arquivos do build que mudam a cada deploy.
const _buildFiles = ['flutter_bootstrap.js', 'main.dart.js'];

/// Recarrega a página já com os arquivos do deploy novo.
///
/// O GitHub Pages deixa o navegador guardar os arquivos em cache por alguns
/// minutos. Um reload comum poderia abrir a versão antiga de novo. Por isso,
/// antes de recarregar, buscamos cada arquivo ignorando o cache
/// (`cache: 'reload'`), o que também deixa o cache com a versão nova.
Future<void> reloadPage() async {
  for (final file in _buildFiles) {
    try {
      await web.window
          .fetch(file.toJS, web.RequestInit(cache: 'reload'))
          .toDart;
    } catch (_) {
      // Sem problema: o reload abaixo acontece mesmo assim.
    }
  }
  web.window.location.reload();
}

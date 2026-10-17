// Import condicional: no navegador vale a versão web (que usa `window`);
// nos testes, que rodam na Dart VM, vale a versão vazia.
export 'page_reloader_stub.dart'
    if (dart.library.js_interop) 'page_reloader_web.dart';

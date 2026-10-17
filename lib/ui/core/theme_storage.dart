// Import condicional: no navegador salva no localStorage; nos testes, nada.
export 'theme_storage_stub.dart'
    if (dart.library.js_interop) 'theme_storage_web.dart';

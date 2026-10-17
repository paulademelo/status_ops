// Import condicional: no navegador abre uma nova aba; nos testes não faz nada.
export 'url_opener_stub.dart'
    if (dart.library.js_interop) 'url_opener_web.dart';

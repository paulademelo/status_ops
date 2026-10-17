import 'package:flutter/foundation.dart';

import 'package:status_ops/ui/core/theme.dart';

/// Lê o tema salvo (ou `null`).
typedef ThemeReader = String? Function();

/// Salva o tema escolhido.
typedef ThemeWriter = void Function(String themeName);

void _doNotSave(String themeName) {}

/// Guarda o tema escolhido e avisa o app quando ele muda.
///
/// A escolha é salva no navegador: sem isso, o tema voltaria para o padrão
/// toda vez que o painel se recarrega sozinho depois de um deploy.
class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeReader? read,
    ThemeWriter? write,
    AppThemeId initial = AppThemeId.grafiteAmbar,
  }) : _write = write ?? _doNotSave,
       _current = AppThemeId.fromName(read?.call()) ?? initial;

  final ThemeWriter _write;
  AppThemeId _current;

  AppThemeId get current => _current;

  AppPalette get palette => _current.palette;

  void select(AppThemeId theme) {
    if (theme == _current) {
      return;
    }
    _current = theme;
    _write(theme.name);
    notifyListeners();
  }
}

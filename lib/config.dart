// 💡 Dica de aula: altere os valores abaixo, faça commit + push na `main`
// e acompanhe o GitHub Actions publicar a nova versão sozinho.

/// Versão exibida no painel. Precisa seguir o padrão `vX.Y.Z` — existe um
/// teste que garante isso. Se ele quebrar, o deploy é cancelado!
const String appVersion = 'v1.0.0';

/// Nome do projeto fictício monitorado pelo painel.
const String projectName = 'Projeto StatusOps';

/// Mensagem de destaque mostrada no banner de produção.
const String statusMessage = 'Deploy automatizado com sucesso!';

/// Repositório consultado ao vivo na API do GitHub (`dono/repo`).
///
/// Pode ser sobrescrito no build com `--dart-define=GITHUB_REPOSITORY=...`
/// (no GitHub Actions essa variável já existe com o repo atual).
const String githubRepository = String.fromEnvironment(
  'GITHUB_REPOSITORY',
  defaultValue: 'paulademelo/status_ops',
);

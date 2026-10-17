# 🚀 Flutter StatusOps - Web CI/CD Dashboard

O **Flutter StatusOps** é uma aplicação web minimalista desenvolvida em Flutter Web para servir de ambiente prático no estudo e implementação de **CI/CD (Integração Contínua e Entrega Contínua)**.

O app é o próprio painel de controle do deploy: ele mostra o status da build, os testes, a versão no ar e os últimos commits do "Projeto StatusOps" — e esses dados são gerados **pela própria esteira** a cada publicação.

## 🎯 Objetivo do Projeto

Demonstrar na prática o ciclo de vida de uma aplicação mobile/web em um ambiente automatizado:

1. **Controle de Versão:** envio de código-fonte para o repositório remoto.
2. **Integração Contínua (CI):** validação automática de formatação, análise estática e execução de testes via GitHub Actions.
3. **Entrega/Implantação Contínua (CD):** compilação automatizada da build de produção (`flutter build web`) e publicação no GitHub Pages.

## 🛠️ Tecnologias Utilizadas

- **Flutter Web** (UI e apresentação)
- **Dart**
- **GitHub Actions** (esteira de CI/CD)
- **GitHub Pages** (hospedagem e deploy automático)

## 🔄 Fluxo do Pipeline

O workflow fica em `.github/workflows/ci_cd.yml` e tem 3 jobs:

| Job | Quando roda | O que faz |
| --- | --- | --- |
| 🧪 **CI - Qualidade e testes** | todo push e pull request | `dart format`, `flutter analyze`, `flutter test` |
| 🏗️ **Build web** | push na `main` com CI verde | gera `build_info.json` (commit, autor, nº da execução, testes, histórico) e roda `flutter build web --release` |
| 🚀 **Deploy GitHub Pages** | depois do build | publica `build/web` no GitHub Pages |

Se qualquer etapa do CI falhar, o build e o deploy **não acontecem** — a versão antiga continua no ar.

### Como os dados chegam ao app?

O Flutter Web gera um site estático, então o app não "escuta" o GitHub. Quem injeta as informações é o pipeline, em tempo de compilação:

```
git log + jq  →  build_info.json  →  flutter build web --dart-define-from-file=build_info.json
```

No código, `lib/build_info.dart` lê esses valores com `String.fromEnvironment`. Rodando localmente (sem o arquivo), o painel mostra "Rodando fora do pipeline".

## 📡 Dados ao vivo

Além dos dados "congelados" no build, o painel consulta a API pública do GitHub enquanto está aberto (`GET /repos/{dono}/{repo}/actions/runs`):

- lista as últimas execuções da `main` e marca a que publicou a página aberta (**no ar**);
- mostra os **jobs da execução em foco ao vivo**: durante um deploy dá para ver qual passo está rodando ("Rodando: 🧪 Rodar testes · passo 6 de 9");
- clicar numa execução ou job abre a página dele no GitHub Actions;
- mostra a **tendência** das últimas execuções (bolinhas verdes/laranja) além da taxa de sucesso;
- calcula a taxa de sucesso e a duração média do pipeline;
- mostra **"Deploy em andamento"** quando há uma execução rodando e **"Nova versão publicada"** quando um deploy mais novo termina;
- atualiza sozinho, sem F5: a cada 15 s durante um deploy e, com o pipeline parado, divide o saldo de requisições que sobrou até o reset da API (60/hora sem token), nunca abaixo de 45 s;
- pausa as consultas quando a aba fica em segundo plano e atualiza na hora quando ela volta;
- quando um deploy novo termina, recarrega a página sozinho em alguns segundos (buscando os arquivos novos sem cache).

> A consulta é feita **sem token** de propósito: tudo que vai num build web é público. Por isso o repositório precisa ser público.

## 🏛️ Arquitetura (MVVM)

```
PipelineRepository (dados)  →  DashboardViewModel (estado + regras)  →  DashboardScreen (UI)
```

- **Repositório:** só busca e converte os dados da API. Nos testes é trocado por um fake.
- **ViewModel (`ChangeNotifier`):** guarda o estado (carregando, erro, execuções), agenda as atualizações e concentra as regras de negócio.
- **Tela:** só desenha o que o ViewModel expõe, usando `ListenableBuilder`.

## 📁 Estrutura

```
lib/
├── main.dart                         # monta repositório → ViewModel → tela
├── config.dart                       # 💡 valores para alterar durante a aula
├── data/
│   ├── build_info.dart               # metadados injetados pelo pipeline
│   ├── models/workflow_run.dart      # execução do GitHub Actions
│   └── pipeline_repository.dart      # acesso à API do GitHub
└── ui/
    ├── core/                         # tema e formatadores
    └── dashboard/
        ├── dashboard_view_model.dart # estado e regras
        ├── dashboard_screen.dart     # layout responsivo
        └── widgets/                  # cards, banner, pipeline, execuções
test/
├── fakes/                            # repositório falso + execuções de exemplo
├── data/                             # modelo e repositório (MockClient)
└── ui/                               # ViewModel e widgets
.github/workflows/ci_cd.yml           # a esteira de CI/CD
```

## ▶️ Rodando localmente

```bash
flutter pub get
flutter run -d chrome
```

Antes de cada push, rode o mesmo que o CI roda:

```bash
dart format .
flutter analyze
flutter test
```

## ☁️ Configuração inicial no GitHub (uma vez só)

1. Crie um repositório público e envie o projeto para a branch `main`.
2. Em **Settings → Pages → Build and deployment → Source**, selecione **GitHub Actions**.
3. Faça um push (ou rode o workflow manualmente em **Actions → CI/CD - Flutter StatusOps → Run workflow**).
4. Ao final, o link aparece no job de deploy: `https://<seu-usuario>.github.io/<nome-do-repo>/`.

> Se o navegador mostrar a versão antiga depois de um deploy, faça um recarregamento forçado (Ctrl+Shift+R / Cmd+Shift+R).

## 🧑‍🏫 Roteiro da aula

1. **O app nasce:** suba o projeto com `appVersion = 'v1.0.0'` e veja o primeiro deploy na aba **Actions**.
2. **A prova real:** em `lib/config.dart`, mude para `v1.0.1` e troque o `statusMessage`. Faça commit + push.
3. **O deploy:** acompanhe os jobs 🧪 → 🏗️ → 🚀. Recarregue a página: versão nova, novo nº de execução e o commit no histórico — sem nenhuma intervenção manual no servidor.
4. **Quebrando de propósito:** mude a versão para `1.0.2` (sem o `v`). O teste `a versão segue o padrão vX.Y.Z` falha, o job de CI fica vermelho e **o deploy é cancelado** — o site continua com a versão anterior.
5. **Pull request:** abra um PR com uma mudança; só o CI roda, nada é publicado até o merge na `main`.

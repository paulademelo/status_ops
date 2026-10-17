# 🚀 Flutter StatusOps - Web CI/CD Dashboard

O **Flutter StatusOps** é uma aplicação web minimalista desenvolvida em Flutter Web para servir de ambiente prático no estudo e implementação de **CI/CD (Integração Contínua e Entrega Contínua)**.

O app é o próprio painel de controle do deploy: ele mostra o status da build, os testes, a versão no ar e os últimos commits do "Projeto Aurora" — e esses dados são gerados **pela própria esteira** a cada publicação.

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

## 📁 Estrutura

```
lib/
├── main.dart                 # entrada do app
├── config.dart               # 💡 valores para alterar durante a aula
├── build_info.dart           # metadados injetados pelo pipeline
├── dashboard_screen.dart     # layout responsivo do painel
├── theme.dart                # cores e tema escuro
└── widgets/                  # cards, banner, pipeline, histórico
test/
└── widget_test.dart          # testes de unidade e de widget
.github/workflows/ci_cd.yml   # a esteira de CI/CD
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

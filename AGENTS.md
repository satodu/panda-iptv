# AGENT CODING INSTRUCTIONS // PANDA IPTV

Quando você atuar neste repositório, você DEVE seguir estritamente estas diretrizes:

## 1. Regras Fundamentais & Inegociáveis para IA

### 1.1 Compatibilidade Absoluta com Firestick, Android TV e TV Box (D-Pad & Controle Remoto)
- **Navegação Direcional D-Pad:** Toda e qualquer tela, modal, aba, formulário, lista ou botão deve ser 100% utilizável via controle remoto de TV (teclas Cima, Baixo, Esquerda, Direita, Enter/OK e Voltar/Back).
- **Proibição de Bloqueio de Foco Raiz:** NUNCA envolva telas inteiras, `Scaffold` ou árvores com widgets `Focus(onKeyEvent: ...)` ou nodes genéricos com `canRequestFocus: true` no nível superior. Isso rouba o foco direcional do Flutter (`FocusTraversalPolicy`), fazendo o destaque visual de seleção sumir e quebrando a navegação no Firestick e TV Box.
- **Atalhos Desktop vs Controle Remoto:** Atalhos de teclado para desktop (como tecla `Escape`) DEVEM usar `Shortcuts` e `Actions` com intents dedicados, que atuam passivamente sem roubar foco de filhos, e NUNCA devem interceptar `LogicalKeyboardKey.goBack` (que é de controle exclusivo do sistema Android).
- **Botão Voltar e Diálogos Persistentes:** O botão Voltar em TVs e TV Boxes deve ser tratado via `PopScope(canPop: false, onPopInvokedWithResult: ...)`. Diálogos modais (como confirmação de saída) DEVEM ter `barrierDismissible: false` e proteção de lock (booleano) para não sumirem ao soltar o botão de voltar (`KeyUp`).
- **Autofoco em Modais:** Qualquer diálogo ou modal aberto deve definir `autofocus: true` em um dos seus botões de ação (preferencialmente Cancelar) para que o controle remoto caia imediatamente sobre um elemento focável dentro do diálogo.
- **Feedback Visual de Foco:** Todo elemento interativo deve usar `BentoCard` ou componentes focusable com borda e glow neon bem definidos quando focados (`_isFocused`), garantindo perfeita visibilidade a 3 metros da tela (experiência 10-foot UI).

### 1.2 Releases Sempre pelo GitHub (CI/CD Actions)
- **Esteira Oficial Automatizada:** Toda release oficial do Panda IPTV (geração de APKs Android, AppImage Linux, bundles `.tar.gz`) DEVE ser executada exclusivamente através da pipeline do GitHub Actions (`.github/workflows/release.yml`), disparada por tags de versão `v*`.
- **Fluxo Obrigatório de Release:**
  1. Atualize a versão e build number no [pubspec.yaml](file:///run/media/panda/panda/Projects/satodu/panda-iptv/pubspec.yaml) (ex: `0.1.3+13`).
  2. Valide que todos os testes passem com `flutter analyze` e `flutter test`.
  3. Comite as alterações no branch `main` e faça o push: `git push origin main`.
  4. Crie a tag anotada ou simples: `git tag vX.Y.Z` e envie para o GitHub: `git push origin vX.Y.Z`.
  5. A esteira compilará os artefatos em ambiente limpo e publicará os binários na página de Releases do GitHub.
  6. Para o Arch User Repository (AUR), atualize o [PKGBUILD](file:///run/media/panda/panda/Projects/satodu/panda-iptv/packaging/aur/PKGBUILD) e [.SRCINFO](file:///run/media/panda/panda/Projects/satodu/panda-iptv/packaging/aur/.SRCINFO) com o sha256 do tarball gerado pela release e envie para o repositório AUR oficial (`panda-iptv-bin`).
- **Padrão Obrigatório de Release Notes (GitHub Releases):**
  - **Idioma:** Sempre exclusivamente em **Inglês técnico**.
  - **Zero Emojis:** NUNCA utilize emojis (nada de 🚀, 📦, 🐛, ✨, etc.) nas notas de release ou changelogs. Mantenha a estética brutalista, minimalista e profissional.
  - **Estrutura:** Título em maiúsculas (`PANDA IPTV V<VERSION> // RELEASE NOTES`), seguido por seções claras em tópicos (`OVERVIEW`, `FIXES & IMPROVEMENTS`, `DISTRIBUTION ARTIFACTS`, `INSTALLATION NOTES`).
- **Nunca fazer releases manuais soltas:** Evite compilar releases manuais localmente para distribuição direta quando a pipeline estiver disponível; a esteira do GitHub garante repetibilidade, assinaturas e integridade dos binários.

### 1.3 Manutenção Crítica do Pacote AUR (`panda-iptv-bin`)
- **Base de Usuários no Arch Linux:** O Panda IPTV possui múltiplos usuários ativos instalando e atualizando via AUR (`paru`, `yay`, `pamac`, `makepkg`). É **estritamente obrigatório** manter o pacote do AUR 100% funcional, testado e atualizado a cada lançamento ou correção.
- **Sincronia Imediata de Checksum (sha256):** Assim que a esteira do GitHub Actions publicar a release e gerar o `panda-iptv-<version>-linux-x64.tar.gz`, o hash sha256 DEVE ser calculado diretamente do arquivo publicado e sincronizado tanto no `PKGBUILD` quanto no `.SRCINFO`.
- **Regra de Bumping de `pkgrel`:**
  - Sempre que for lançado um novo `pkgver` (nova versão do app, ex: `1.0.1`), resetar `pkgrel=1`.
  - Se houver QUALQUER alteração no pacote, no binário, ou correção de checksum SEM alteração do `pkgver` do app, você **DEVE obrigatoriamente incrementar o `pkgrel`** (ex: de `1` para `2`), atualizar o `.SRCINFO` e subir para o AUR. Se não incrementar o `pkgrel`, os gerenciadores como `paru` e `yay` reutilizarão o arquivo quebrado em cache dos usuários gerando erro de hash!
- **Repositório Oficial do AUR:** As alterações no AUR devem ser commitadas e enviadas diretamente para `ssh://aur@aur.archlinux.org/panda-iptv-bin.git` (branch `master`) além de espelhadas no repositório principal do GitHub (`packaging/aur/`).

---

## 2. Identidade Visual Obrigatória
- O projeto segue o **Oriental Brutalismo Minimalista** com **Azul Elétrico** como cor principal.
- Consulte sempre [DESIGN_SYSTEM.md](file:///run/media/panda/panda/Projects/satodu/panda-iptv/DESIGN_SYSTEM.md).
- Paleta:
  - Fundo Canvas: `#0D1216`
  - Painéis / Cards Bento: `#141A1F`
  - Hover / Ativo: `#1C242C`
  - Destaque Principal: `#0A84FF`
  - Texto Principal: `#DEDFD7`
  - Texto Secundário: `#7E8790`
- Títulos: Sempre em CAIXA-ALTA e terminando com PONTO FINAL (ex: `AO VIVO.`, `CONFIGURAÇÕES.`, `FILMES.`).
- Detalhes sutis: Sequências técnicas de cruzes (`+ + +`), tags mono entre colchetes (`[ 1080P ]`, `[ LIVE ]`).

## 3. Padrões Técnicos do Flutter
- O aplicativo é multiplataforma: **Linux Desktop** e **Android**.
- Todo componente de tela deve suportar tanto orientação **Vertical** (modo celular portrait) quanto **Horizontal** (modo desktop / landscape / TV).
- Nunca use valores absolutos de tamanho de tela que quebrem em rotação ou telas menores.
- Gerenciamento de estado: Mantenha a separação entre UI (Presentation), Estado e Serviços de Dados (Clean Architecture).
- Mídia: O player de vídeo deve usar `media_kit` (alimentado por `libmpv`) para máxima performance com aceleração de hardware tanto no Linux quanto no Android.
- API: Protocolo Xtream Codes (`player_api.php`). Detalhes em [PROJECT_GUIDE.md](file:///run/media/panda/panda/Projects/satodu/panda-iptv/PROJECT_GUIDE.md).

## 4. Internacionalização Obrigatória (i18n)
- Suporte nativo a 3 idiomas: **Português (`pt_BR`)**, **Inglês (`en_US`)** e **Espanhol (`es_ES`)**.
- Arquivos de tradução em JSON sob `assets/i18n/`.
- Consulte o guia completo em [I18N_GUIDE.md](file:///home/panda/orca/workspaces/panda-iptv/fiddler/I18N_GUIDE.md).
- **Regras para Agentes**:
  1. Nunca adicione textos de tela como strings literais (hardcoded). Use `context.tr('categoria.chave')`.
  2. Ao adicionar uma nova chave, você **DEVE** adicioná-la simultaneamente em `pt_BR.json`, `en_US.json` e `es_ES.json`.
  3. Mantenha os títulos em **CAIXA-ALTA com PONTO FINAL** em todos os idiomas (ex: `"AO VIVO."`, `"LIVE TV."`, `"EN VIVO."`).

## 5. Releases, Builds & Empacotamento
- **Versionamento:** A versão oficial do aplicativo é definida em [pubspec.yaml](file:///run/media/panda/panda/Projects/satodu/panda-iptv/pubspec.yaml) (ex: `0.1.3+13`). Sempre consulte e atualize lá antes de gerar releases.
- **Builds Linux & AppImage:**
  - Script automatizado: [scripts/build_release.sh](file:///run/media/panda/panda/Projects/satodu/panda-iptv/scripts/build_release.sh).
  - Gera os artefatos finais na pasta `dist/`:
    - `dist/Panda-IPTV-<version>-x86_64.AppImage` (executável portátil universal Linux).
    - `dist/panda-iptv-<version>-linux-x64.tar.gz` (bundle compactado para distribuição).
  - AppImage script individual: [packaging/appimage/build_appimage.sh](file:///run/media/panda/panda/Projects/satodu/panda-iptv/packaging/appimage/build_appimage.sh).
- **Arch User Repository (AUR):**
  - O template oficial do `PKGBUILD` reside em [packaging/aur/PKGBUILD](file:///run/media/panda/panda/Projects/satodu/panda-iptv/packaging/aur/PKGBUILD) para o pacote `panda-iptv-bin`.
- **Android:**
  - Build APK direta: `flutter build apk --release` (ou `--split-per-abi`).
  - Build Play Store: `flutter build appbundle --release`.

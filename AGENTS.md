# AGENT CODING INSTRUCTIONS // PANDA IPTV

Quando você atuar neste repositório, você DEVE seguir estritamente estas diretrizes:

## 1. Identidade Visual Obrigatória
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

## 2. Padrões Técnicos do Flutter
- O aplicativo é multiplataforma: **Linux Desktop** e **Android**.
- Todo componente de tela deve suportar tanto orientação **Vertical** (modo celular portrait) quanto **Horizontal** (modo desktop / landscape / TV).
- Nunca use valores absolutos de tamanho de tela que quebrem em rotação ou telas menores.
- Gerenciamento de estado: Mantenha a separação entre UI (Presentation), Estado e Serviços de Dados (Clean Architecture).
- Mídia: O player de vídeo deve usar `media_kit` (alimentado por `libmpv`) para máxima performance com aceleração de hardware tanto no Linux quanto no Android.
- API: Protocolo Xtream Codes (`player_api.php`). Detalhes em [PROJECT_GUIDE.md](file:///run/media/panda/panda/Projects/satodu/panda-iptv/PROJECT_GUIDE.md).

## 3. Internacionalização Obrigatória (i18n)
- Suporte nativo a 3 idiomas: **Português (`pt_BR`)**, **Inglês (`en_US`)** e **Espanhol (`es_ES`)**.
- Arquivos de tradução em JSON sob `assets/i18n/`.
- Consulte o guia completo em [I18N_GUIDE.md](file:///home/panda/orca/workspaces/panda-iptv/fiddler/I18N_GUIDE.md).
- **Regras para Agentes**:
  1. Nunca adicione textos de tela como strings literais (hardcoded). Use `context.tr('categoria.chave')`.
  2. Ao adicionar uma nova chave, você **DEVE** adicioná-la simultaneamente em `pt_BR.json`, `en_US.json` e `es_ES.json`.
  3. Mantenha os títulos em **CAIXA-ALTA com PONTO FINAL** em todos os idiomas (ex: `"AO VIVO."`, `"LIVE TV."`, `"EN VIVO."`).

## 4. Releases, Builds & Empacotamento
- **Versionamento:** A versão oficial do aplicativo é definida em [pubspec.yaml](file:///run/media/panda/panda/Projects/satodu/panda-iptv/pubspec.yaml) (ex: `0.0.1-alpha+1`). Sempre consulte e atualize lá antes de gerar releases.
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

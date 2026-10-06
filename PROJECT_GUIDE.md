# PANDA IPTV // ARQUITETURA E GUIA DO PROJETO (AI CONTEXT)
> Guia técnico mestre para desenvolvimento em Flutter (Linux & Android)

Este arquivo serve como contexto completo para qualquer Agente de IA ou desenvolvedor trabalhando no repositório **Panda IPTV**.

---

## 1. VISÃO GERAL DO PRODUTO

O **Panda IPTV** é um reprodutor moderno de IPTV baseado no protocolo **Xtream Codes API**, utilizando uma linguagem visual proprietária baseada no estilo **Oriental Brutalismo Minimalista** com destaque em **Azul Elétrico**.

### Plataformas Alvo:
* **Linux Desktop** (Arch Linux, Fedora, Ubuntu, Flatpak) com foco em mouse, teclado e atalhos.
* **Android** (Smartphones, Tablets e Android TV / TV Box) com suporte a touch e controle remoto D-Pad.
* **Múltiplas Orientações**: Totalmente adaptável tanto em modo vertical (*portrait*) quanto horizontal (*landscape*).

---

## 2. ARQUITETURA DA CENTRAL DE MÍDIA (EXPERIÊNCIA DO USUÁRIO)

O aplicativo é uma central multimídia organizada e de alta performance:

1. **Dashboard Inicial (Hub)**:
   * **Hero Banner Dinâmico**: Último canal assistido ou destaque de transmissão ao vivo.
   * **Continuar Assistindo**: Histórico de canais recentes e filmes em andamento com barra de progresso.
   * **Bento de Categorias**: Ao Vivo (`TV.`), Filmes (`VOD.`), Séries (`SERIES.`), Favoritos (`FAV.`).
   * **EPG Hoje (Guia de Programação)**: O que está passando agora nos canais favoritos.
2. **Ao Vivo (Live TV)**:
   * Categorias colapsáveis à esquerda (em modo horizontal) ou em abas (em modo vertical).
   * Grade de canais com logos, nome do programa atual e barra de tempo restante.
   * Mini-player picture-in-picture ou preview antes de tela cheia.
3. **Filmes e Séries (VOD)**:
   * Cartões de pôsteres com visual brutalista limpo, classificação indicativa e ano.
   * Tela de detalhes do filme/série com sinopse, elenco, trailer e seleção de episódios por temporadas.
4. **Player de Vídeo**:
   * OSD (On-Screen Display) minimalista que desaparece após inatividade.
   * Troca rápida de canais com numeração ou seta direcional.
   * Controle de áudio, legendas e taxa de proporção (16:9, 4:3, Zoom, Ajustar).
   * Suporte a reprodução contínua e reconexão automática em caso de instabilidade de rede.

---

## 3. ESPECIFICAÇÃO DA API XTREAM CODES

Toda comunicação com o servidor IPTV é feita via chamadas HTTP JSON na URL base:
`http://{host}:{port}/player_api.php?username={user}&password={pass}`

### Principais Ações (`&action=...`):
* **Autenticação & Info da Conta**:
  * Requisição: `GET /player_api.php?username={u}&password={p}`
  * Retorno: Objeto `user_info` (status, exp_date, max_connections, is_trial) e `server_info` (url, porta, timezone).
* **Canais Ao Vivo**:
  * Categorias: `&action=get_live_categories`
  * Streams: `&action=get_live_streams&category_id={id}`
  * URL do Fluxo: `http://{host}:{port}/{username}/{password}/{stream_id}.ts` (ou `.m3u8`)
* **Filmes (VOD)**:
  * Categorias: `&action=get_vod_categories`
  * Filmes: `&action=get_vod_streams&category_id={id}`
  * Detalhes: `&action=get_vod_info&vod_id={vod_id}`
  * URL do Fluxo: `http://{host}:{port}/movie/{username}/{password}/{stream_id}.{container_extension}`
* **Séries**:
  * Categorias: `&action=get_series_categories`
  * Lista: `&action=get_series&category_id={id}`
  * Temporadas e Episódios: `&action=get_series_info&series_id={series_id}`
* **Guia de Programação (EPG)**:
  * Guia resumido: `&action=get_short_epg&stream_id={stream_id}&limit=5`

---

## 4. ESTRUTURA DE DIRETÓRIOS DO CÓDIGO (CLEAN ARCHITECTURE / FEATURE-FIRST)

```
lib/
├── core/
│   ├── api/                 # Cliente HTTP Xtream Codes, interceptores e cache
│   ├── constants/           # Constantes globais e chaves de storage
│   ├── localization/        # Sistema i18n JSON (AppLocalizations, LocaleProvider)
│   ├── network/             # Gerenciamento de conectividade e tratamento de erros
│   ├── storage/             # Cache local de credenciais, histórico e favoritos
│   ├── theme/
│   │   ├── app_colors.dart  # Tokens de cores (Surface-0, Surface-1, Accent Blue)
│   │   ├── app_theme.dart   # ThemeData do Flutter personalizado
│   │   └── app_typography.dart # Estilos de texto (Grotesk, Monospace, pontos secos)
│   └── widgets/             # Componentes reutilizáveis
│       ├── bento_card.dart  # Card base com borda 1px e padding 'Ma'
│       ├── brutalist_button.dart # Botões primários com estilo do guia
│       ├── tech_crosses.dart # Padrão decorativo (+ + +)
│       └── hanko_badge.dart # Selo estilizado
├── features/
│   ├── auth/                # Login com servidor, usuário e senha
│   │   ├── data/            # Repositórios e fontes de dados da autenticação
│   │   ├── models/          # Modelos de UserInfo, ServerInfo e Account
│   │   └── presentation/    # Telas de login e gerenciamento de perfis
│   ├── dashboard/           # Tela inicial da Central de Mídia / Bento Hub
│   ├── live_tv/             # Navegação de canais, categorias e EPG
│   ├── vod/                 # Catálogo de filmes e detalhes
│   ├── series/              # Séries, temporadas e episódios
│   ├── player/              # Player de vídeo integrado via media_kit (MPV)
│   └── settings/            # Configurações de exibição, buffer e reprodução
└── main.dart                # Inicialização de serviços e ponto de entrada
```

---

## 5. REGRAS PARA ASSISTENTES DE IA E CONTRIBUIDORES

1. **Sempre respeitar o [DESIGN_SYSTEM.md](file:///run/media/panda/panda/Projects/satodu/panda-iptv/DESIGN_SYSTEM.md)**:
   - Nunca use botões com cantos redondos infantis ou gradientes roxos/rosas fora da paleta.
   - Utilize fundo `#0D1216`, cartões `#141A1F` e destaques em `#0A84FF`.
   - Todos os títulos principais de seções devem terminar com ponto final: `EX: CANAIS AO VIVO.`
2. **Responsividade Obligatória**:
   - Todo componente deve funcionar elegantemente em tela vertical (celular 9:16) e horizontal (desktop/TV 16:9).
   - Use `LayoutBuilder`, `MediaQuery` e `Flex` adaptáveis.
3. **Internacionalização Obrigatória (i18n)**:
   - Toda string apresentada na interface deve estar mapeada nos 3 arquivos JSON sob `assets/i18n/` (`pt_BR.json`, `en_US.json`, `es_ES.json`).
   - Consulte [I18N_GUIDE.md](file:///home/panda/orca/workspaces/panda-iptv/fiddler/I18N_GUIDE.md) para convenções de nomenclatura e exemplos.
4. **Performance de Mídia no Linux & Android**:
   - Para reproduzir streams HLS/TS com alta performance no Linux e Android, a biblioteca recomendada é o `media_kit` (alimentada nativamente pelo `libmpv`), garantindo suporte total a aceleração por hardware (VA-API / NVDEC no Linux, MediaCodec no Android).
5. **Tratamento de Falhas**:
   - Servidores de IPTV podem oscilar. Sempre tratar timeouts com elegância e apresentar mensagens amigáveis no padrão visual do app.

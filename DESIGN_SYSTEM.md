# DESIGN SYSTEM // ORIENTAL BRUTALISMO MINIMALISTA (BLUE ACCENT)
> Versão 1.0.0 | Guia de Design Tokens e Regras de Interface para o **Panda IPTV**

Este documento define rigorosamente todos os tokens visuais, componentes, espaçamentos e regras estéticas extraídas do manual de arte e adaptadas para a identidade **Azul Elétrico**. Qualquer agente de IA ou desenvolvedor **DEVE** seguir estas diretrizes ao criar telas ou componentes.

---

## 1. TOKENS DE COR E SUPERFÍCIE (STRICT PALETTE)

Nunca utilize cores genéricas do Material Design ou temas padrões saturados.

| Token | Código HEX | RGB / Opacidade | Descrição & Aplicação |
| :--- | :--- | :--- | :--- |
| **`surface-0` (Canvas)** | `#0D1216` | `rgb(13, 18, 22)` | Preto mineral profundo, acabamento mate. Fundo de todas as telas. |
| **`surface-1` (Cards/Bento)** | `#141A1F` | `rgb(20, 26, 31)` | Grafite escuro fosco. Módulos Bento, painéis e barras laterais. |
| **`surface-2` (Hover/Active)** | `#1C242C` | `rgb(28, 36, 44)` | Superfícies interativas em hover, foco ou seleção. |
| **`surface-dialog`** | `#11161B` | `rgba(17, 22, 27, 0.95)` | Modais, menus de contexto e players com backdrop blur. |
| **`border-hairline`** | `#DEDFD7` | `rgba(222, 223, 215, 0.08)` | Bordas estruturais de 1px ultrafinas. |
| **`border-active`** | `#0A84FF` | `rgba(10, 132, 255, 0.40)` | Borda de elemento selecionado ou com foco de navegação. |
| **`accent-primary`** | `#0A84FF` | `rgb(10, 132, 255)` | **Azul Elétrico**. Botões primários, badges de destaque, barras de progresso ativas. |
| **`accent-glow`** | `#0A84FF` | `rgba(10, 132, 255, 0.20)` | Glow suave e cirúrgico em estados ativos. |
| **`accent-secondary`** | `#00D2FF` | `rgb(0, 210, 255)` | Azul ciano técnico para indicadores de live, bitrate e resolução. |
| **`text-primary`** | `#DEDFD7` | `rgb(222, 223, 215)` | Off-white nítido fosco para títulos, rótulos e texto principal. |
| **`text-muted`** | `#7E8790` | `rgb(126, 135, 144)` | Cinza intermediário para metadados, durações, EPG e números. |
| **`text-disabled`** | `#3A444C` | `rgb(58, 68, 76)` | Textos secundários inativos ou placeholders sutis. |
| **`status-live`** | `#00E5FF` | `rgb(0, 229, 255)` | Indicador de transmissão ao vivo em andamento. |
| **`status-error`** | `#FF453A` | `rgb(255, 69, 58)` | Falha de autenticação ou erro de stream. |

---

## 2. TIPOGRAFIA E HIERARQUIA

### Regras de Títulos (Display):
* **Família**: Sans-serif geométrica pesada (Space Grotesk, Syne ou similar).
* **Estilo**: Caixa-alta (`UPPERCASE`), peso `FontWeight.w800` ou `w900`, tracking justo (`letterSpacing: -0.5`).
* **Pontuação Seca**: **Todo título principal deve terminar com ponto final.**
  * Exemplos: `PANDA IPTV.`, `AO VIVO.`, `FILMES RECENTES.`, `CONFIGURAÇÕES.`, `ENTRAR.`

### Corpo e UI Geral:
* **Família**: Inter / Plus Jakarta Sans, pesos `FontWeight.w400` e `w500`.

### Metadados e Tags Técnicas (Mono & Oriental):
* **Família**: JetBrains Mono ou monospace do sistema.
* **Prefixo Pontuado**: Tags como `In.`, `Live.`, `Ch.01`, `[ 1080P ]`, `FHD.`, `H.264`.
* **Colunas Orientais / Selos Hanko**:
  * Caracteres japoneses como linha decorativa e âncora estrutural (ex: `パンダ` para Panda, `放送` para Transmissão).
  * Selo Hanko estilizado: Uma badge compacta retangular ou quadrada com borda azul e fundo translúcido contendo um glifo ou sigla.

---

## 3. ESTRUTURA E LAYOUT (BENTO GRID + CONCEITO 'MA')

* **Bento Grid Rígido**: Módulos organizados com espaçamento fixo (`gap: 12` a `gap: 16`).
* **Espaço Negativo ('Ma')**: Respiros generosos (`padding: 20` a `28`), evitando aglomeração excessiva de informações.
* **Cantos e Arredondamento**:
  * Cantos externos modernos: `BorderRadius.circular(14)` a `18`.
  * Bordas: Sempre ultrafinas `1.0` pixel com cor `border-hairline`.

---

## 4. MICRO-DETALHES DECORATIVOS

1. **Cruzes Técnicas (`+ + +`)**: Sequência sutil de alinhamento em áreas com espaço livre, usando opacidade de `15%` a `25%`.
2. **Grids de Pontos (Dot Matrix)**: Padrões discretos de pontos de fundo para conferir textura tátil e profundidade.
3. **Badges Pílula / Selos Hanko**: Tags com borda de 1px azul e texto monospace.
4. **Anéis Finos**: Círculos gráficos vetoriais sutis como elementos decorativos de fundo.

---

## 5. RESPONSIVIDADE E ORIENTAÇÃO

* **Horizontal (Desktop Linux & TV / Celular Paisagem)**:
  * Inspirado na arquitetura do **Jellyfin / Emby**:
  * Barra de navegação lateral retrátil (Sidebar).
  * Grade Bento com hero banner em destaque, carrossel de canais ao vivo, filmes recentes e séries.
* **Vertical (Celular Retrato)**:
  * Barra de navegação inferior flutuante (Bottom Navigation Bar translúcida).
  * Módulos adaptados em lista vertical com rolagem horizontal interna para categorias.

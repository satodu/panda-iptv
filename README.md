<p align="center">
  <img src="assets/images/logo.png" width="160" height="160" alt="Panda IPTV Logo" style="border-radius: 24px;" />
</p>

<h1 align="center">PANDA IPTV.</h1>

<p align="center">
  <b>Reprodutor Multimídia IPTV Moderno com Identidade Oriental Brutalismo Minimalista.</b><br/>
  Construído em Flutter para <b>Linux Desktop</b> e <b>Android</b>, alimentado pela aceleração nativa de vídeo do <b>libmpv</b>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Linux_Desktop-%23FCC624.svg?style=for-the-badge&logo=linux&logoColor=black" alt="Linux Desktop" />
  <img src="https://img.shields.io/badge/Android-%233DDC84.svg?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Player-libmpv-0A84FF?style=for-the-badge" alt="libmpv" />
  <img src="https://img.shields.io/badge/Design-Oriental_Brutalism-0D1216?style=for-the-badge&labelColor=0A84FF" alt="Oriental Brutalism" />
  <a href="https://ko-fi.com/retro_panda" target="_blank"><img src="https://img.shields.io/badge/Ko--fi-Apoie_o_Projeto-%23FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Ko-fi" /></a>
</p>

---

## VISÃO GERAL.

O **Panda IPTV** é uma central multimídia de alta performance para reprodução de listas e conteúdos sob o protocolo **Xtream Codes API**. Rompendo com interfaces genéricas, o Panda adota uma identidade autoral baseada no **Oriental Brutalismo Minimalista**: tipografia geométrica pesada em caixa-alta com ponto final seco, layout Bento modular com respiros equilibrados (*conceito japonês 'Ma'*) e acentos cirúrgicos em **Azul Elétrico** (`#0A84FF`).

---

## DESTAQUES & FUNCIONALIDADES.

* **Central Multimídia Completa:**
  * **Filmes (VOD):** Catálogo completo com busca em tempo real, filtros por categorias (iniciando em `TODOS`), pôsteres em alta definição, sinopse, elenco, diretor, ano e classificação.
  * **Séries:** Organização por temporadas e episódios com metadados, tempo de duração e reprodução direta com um clique.
  * **Canais Ao Vivo:** Suporte à navegação de transmissões em tempo real via Xtream API.
  * **Hub Central (Dashboard):** Visão geral da conexão ativa, badges técnicos de bitrate/resolução e atalhos rápidos.

* **Player de Vídeo de Alta Performance (libmpv):**
  * OSD (On-Screen Display) minimalista que se recolhe automaticamente após inatividade.
  * **Controle de Volume Dedicado:** Slider interativo no player, atalhos de teclado e ajuste suave pelo scroll do mouse.
  * **Seletor Dinâmico de Decodificador (Hardware / Software):** Compatibilidade total com distribuições Linux modernas (incluindo **Wayland + Nvidia**) com decodificação segura `hwdec=no` por padrão para evitar telas azuis ou falhas de textura GL, além de alternância ao vivo para `auto-copy` ou `auto`.
  * **Headers de Player Profissional:** Simulação transparente de User-Agent de player IPTV (`IPTVSmartersPro/3.1.5`) para contornar bloqueios comuns de provedores.

* **Autenticação & Sessão Inteligente:**
  * **Login Automático & Lembrar Credenciais:** Opção de auto-login persistente via `SharedPreferences`.
  * **Tratamento Automático de URL:** Normalização automática de URLs com ou sem barras finais (`/`, `///`), inclusão de `http://` caso ausente e limpeza de sufixos colados acidentalmente (como `/player_api.php` ou `/get.php`).
  * Mesmo após desconectar, o servidor e usuário permanecem pré-preenchidos para agilidade.

* **Totalmente Responsivo:**
  * Adaptação fluida para **Desktop Horizontal** (Linux) e **Mobile Vertical/Horizontal** (Android Smartphones, Tablets e TV Boxes).

---

## ATALHOS DO PLAYER DE VÍDEO.

Ao reproduzir qualquer filme, série ou canal no desktop:

| Tecla / Ação | Função |
| :--- | :--- |
| **Espaço** | Pausar / Reproduzir (`Play/Pause`) |
| **Seta $\rightarrow$** | Avançar 10 segundos (`+10s`) |
| **Seta $\leftarrow$** | Retroceder 10 segundos (`-10s`) |
| **Seta $\uparrow$** | Aumentar volume (+5%) |
| **Seta $\downarrow$** | Diminuir volume (-5%) |
| **Scroll do Mouse** | Aumentar / diminuir volume na posição do ponteiro |
| **M** | Mutar / Desmutar áudio |
| **D** | Alternar modo de decodificação (`SW Seguro` / `Auto-Copy` / `HW`) |
| **ESC** | Sair do player e voltar aos detalhes |

---

## ARQUITETURA DE CÓDIGO (CLEAN ARCHITECTURE / FEATURE-FIRST).

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart        # Tokens da paleta (Preto mineral, Azul Elétrico, Ciano)
│   │   ├── app_theme.dart         # Tema escuro brutalista
│   │   └── app_typography.dart    # Grotesk + JetBrains Mono + Noto Sans JP
│   └── widgets/
│       ├── bento_card.dart        # Painéis modulares Bento
│       ├── brutalist_button.dart  # Botões de ação em Azul Elétrico
│       ├── hanko_badge.dart       # Selos orientais e tags de status
│       └── tech_crosses.dart      # Elementos decorativos técnicos (+ + +)
├── features/
│   ├── auth/                      # Login, modelos de conta e validação Xtream
│   ├── dashboard/                 # Tela inicial e grade Bento de navegação
│   ├── vod/                       # Catálogo de filmes e telas de detalhes
│   ├── series/                    # Catálogo de séries, temporadas e episódios
│   └── player/                    # Player integrado media_kit (libmpv) com OSD
└── main.dart                      # Inicialização de dependências nativas e Providers
```

---

## COMO EXECUTAR EM DESENVOLVIMENTO.

### Pré-requisitos:
* **Flutter SDK:** `>= 3.10.0`
* **Linux (Arch, Ubuntu, Fedora):** Ter o pacote `mpv` e `libmpv` instalado no sistema:
  ```bash
  # Arch Linux
  sudo pacman -S mpv
  
  # Ubuntu / Debian
  sudo apt install libmpv-dev mpv
  
  # Fedora
  sudo dnf install mpv-libs-devel mpv
  ```

### Executando no Linux Desktop:
```bash
flutter run -d linux
```

### Executando no Android:
Conecte o smartphone ou emulador via USB com depuração ativada e execute:
```bash
flutter run
```

### Durante o Desenvolvimento (Hot Reload):
* Pressione **`r`** no terminal para **Hot Reload** instantâneo.
* Pressione **`R`** para **Hot Restart** do aplicativo.
* Pressione **`q`** para sair.

---

## APOIE O PROJETO (KO-FI).

Se você gosta do **Panda IPTV** e deseja apoiar o desenvolvimento contínuo:

<p align="center">
  <a href="https://ko-fi.com/retro_panda" target="_blank">
    <img src="https://storage.ko-fi.com/cdn/kofi3.png?v=3" height="38" alt="Buy Me a Coffee at ko-fi.com" />
  </a>
</p>

☕ **Apoie em:** [ko-fi.com/retro_panda](https://ko-fi.com/retro_panda)

---

## LICENÇA.

Desenvolvido para uso pessoal e projetos sob demanda. Todos os direitos reservados.

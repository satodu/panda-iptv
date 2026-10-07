# PANDA IPTV // GUIA DE INSTALAÇÃO & DOWNLOADS.

+ + + [ ORIENTAL BRUTALISMO MINIMALISTA ] + + +

Este guia explica como instalar o **Panda IPTV** em todas as plataformas suportadas: **Amazon Fire TV**, **Celulares & Tablets Android** e **Linux Desktop**.

---

## 📺 1. AMAZON FIRE TV & ANDROID TV (RECOMENDADO)

Instale em menos de 1 minuto em qualquer **Fire TV Stick**, **Mi Box**, **Chromecast com Google TV** ou TV Android:

* **Código do Downloader (AFTV):**  
  👉 `9916531`
* **Link Curto Oficial:**  
  👉 [https://aftv.news/9916531](https://aftv.news/9916531)
* **Link Direto (Latest):**  
  👉 `https://github.com/satodu/panda-iptv/releases/latest/download/Panda-IPTV.apk`

### Passo a Passo:
1. Abra o aplicativo **Downloader** na sua TV (gratuito na loja da Amazon ou Google Play).
2. Vá nas configurações do seu Fire TV em:  
   `Configurações` -> `Meu Fire TV` -> `Opções de Desenvolvedor` -> `Instalar apps desconhecidos` -> Ative para o **Downloader**.  
   *(Se "Opções de Desenvolvedor" estiver oculto, clique 7 vezes sobre o nome do seu Fire TV em "Informações").*
3. Abra o Downloader, digite o código **`9916531`** na barra de URL e clique em **Go**.
4. O APK será baixado e o assistente de instalação abrirá na tela. Confirme em **Instalar**.

---

## 📱 2. CELULAR & TABLET ANDROID

O Panda IPTV suporta nativamente o modo vertical (portrait) com interface adaptada ao toque:

* **Download Direto do APK:**  
  👉 [Panda-IPTV.apk (Versão Mais Recente)](https://github.com/satodu/panda-iptv/releases/latest/download/Panda-IPTV.apk)
* **Download da Versão v0.0.9:**  
  👉 [Panda-IPTV-0.0.9.apk](https://github.com/satodu/panda-iptv/releases/download/v0.0.9/Panda-IPTV-0.0.9.apk)

### Passo a Passo:
1. Baixe o APK pelo link acima no seu smartphone ou tablet.
2. Quando o navegador solicitar, permita **"Instalar aplicativos de fontes desconhecidas"**.
3. Toque na notificação de download ou no arquivo baixado e clique em **Instalar**.
4. Abra o Panda IPTV e insira suas credenciais Xtream Codes.

---

## 🐧 3. LINUX DESKTOP

O aplicativo roda com aceleração nativa via `libmpv` e renderizador Impeller:

### Opção A: AppImage Portátil Universal (Recomendado)
Baixe o arquivo na release:
* 👉 [Panda-IPTV-0.0.9-x86_64.AppImage](https://github.com/satodu/panda-iptv/releases/download/v0.0.9/Panda-IPTV-0.0.9-x86_64.AppImage)

Execute no terminal:
```bash
# 1. Conceda permissão de execução
chmod +x Panda-IPTV-*.AppImage

# 2. Execute
./Panda-IPTV-*.AppImage
```

> **Dica (Se o sistema não tiver FUSE 2):**  
> Execute com `--appimage-extract-and-run` ou instale o pacote `fuse2` (Arch: `sudo pacman -S fuse2` | Ubuntu: `sudo apt install libfuse2`).

### Opção B: Tarball Portátil (.tar.gz)
Sem necessidade de FUSE:
```bash
tar -xzf panda-iptv-0.0.9-linux-x64.tar.gz
./bundle/panda_iptv
```

### Opção C: Arch Linux (AUR)
```bash
yay -S panda-iptv-bin
```

---

## 🌐 GITHUB PAGES / SITE ONLINE

A página web interativa do guia de instalação está disponível na pasta `docs/index.html`.  
Ao ativar o **GitHub Pages** no repositório apontando para `/docs`, o site fica acessível publicamente em:
👉 `https://satodu.github.io/panda-iptv/`

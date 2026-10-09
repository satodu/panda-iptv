<p align="center">
  <img src="assets/images/logo.png" width="160" height="160" alt="Panda IPTV Logo" style="border-radius: 24px;" />
</p>

<h1 align="center">PANDA IPTV.</h1>

<p align="center">
  <b>Modern IPTV Multimedia Player with Oriental Minimalist Brutalism Design.</b><br/>
  Engineered with Flutter for <b>Linux Desktop</b>, <b>Windows Desktop</b>, <b>Android TV</b>, <b>Fire TV Stick</b> and <b>Mobile</b>, powered by native <b>libmpv</b> hardware acceleration.
</p>

<p align="center">
  <a href="https://github.com/satodu/panda-iptv/releases/latest"><img src="https://img.shields.io/github/v/release/satodu/panda-iptv?style=for-the-badge&color=0A84FF&label=Release" alt="Latest Release" /></a>
  <a href="https://aur.archlinux.org/packages/panda-iptv-bin"><img src="https://img.shields.io/aur/version/panda-iptv-bin?style=for-the-badge&color=1793D1&logo=arch-linux&logoColor=white&label=AUR" alt="AUR Version" /></a>
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Windows_Desktop-%230078D6.svg?style=for-the-badge&logo=windows&logoColor=white" alt="Windows Desktop" />
  <img src="https://img.shields.io/badge/Linux_Desktop-%23FCC624.svg?style=for-the-badge&logo=linux&logoColor=black" alt="Linux Desktop" />
  <img src="https://img.shields.io/badge/Android_TV_%26_Mobile-%233DDC84.svg?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Player-libmpv-0A84FF?style=for-the-badge" alt="libmpv" />
  <img src="https://img.shields.io/badge/Design-Oriental_Brutalism-0D1216?style=for-the-badge&labelColor=0A84FF" alt="Oriental Brutalism" />
  <a href="https://satodu.github.io/panda-iptv/" target="_blank"><img src="https://img.shields.io/badge/Official_Website-satodu.github.io%2Fpanda--iptv-0A84FF?style=for-the-badge&logo=github&logoColor=white" alt="Official Website" /></a>
  <a href="https://ko-fi.com/retro_panda" target="_blank"><img src="https://img.shields.io/badge/Ko--fi-Support_the_Project-%23FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Ko-fi" /></a>
</p>

<p align="center">
  🌐 <b>Official Download & Installation Page:</b> <a href="https://satodu.github.io/panda-iptv/"><b>https://satodu.github.io/panda-iptv/</b></a>
</p>

---

## OVERVIEW.

**Panda IPTV** is a high-performance multimedia center designed for streaming playlists and on-demand content through the **Xtream Codes API** protocol. Breaking away from generic IPTV templates, Panda introduces a signature **Oriental Minimalist Brutalism** design language: bold geometric uppercase typography with abrupt periods, modular Bento grid layouts with balanced spatial breathing room (*the Japanese aesthetic concept 'Ma'*), and surgical accents in **Electric Blue** (`#0A84FF`).

Engineered from the ground up for both **10-foot UI (TV & Remote Controls)** and **Desktop / Mobile**, ensuring zero focus traps, blazing-fast hardware-accelerated playback with `media_kit` (`libmpv`), and native multi-language support.

---

## IMPORTANT LEGAL DISCLAIMER & ANTI-PIRACY POLICY.

> [!IMPORTANT]
> **Panda IPTV is strictly a generic media player client and multimedia player.**
>
> 1. **Zero Content Provided:** Panda IPTV **does NOT provide, host, supply, bundle, archive, or resell any digital content**, streams, television channels, movies, series, or playlists. The application comes completely devoid of any pre-configured media or server endpoints.
> 2. **Bring Your Own Content (BYOC):** The application is purely an interface (client). Users are solely and exclusively responsible for providing their own legally obtained playlist credentials or streaming links (such as legitimate Xtream Codes API credentials).
> 3. **Anti-Piracy Compliance:** The developers of Panda IPTV strictly condemn and **do not condone or facilitate copyright infringement, media piracy, or unauthorized distribution of intellectual property**. Users must hold all necessary rights, licenses, or explicit permissions from content owners to stream any media through this application.
> 4. **No Third-Party Affiliation:** Panda IPTV is an independent open-source software project. It is **not affiliated, endorsed, sponsored, or associated** with any third-party IPTV providers, streaming services, or resellers.

---

## KEY FEATURES.

* **Complete Multimedia Hub:**
  * **Movies (VOD):** Comprehensive catalog with optimized search confirmed via Enter or TV remote, auto-reset upon exit for fluid navigation, category filters (defaulting to `ALL`), high-resolution posters, plot synopses, cast, director, release year, age rating, and watched markers.
  * **Series & Binge-Watching:** Full season and episode hierarchy, runtimes, next/previous episode transitions, and automatic 6-second countdown cards to play next episodes seamlessly.
  * **Live TV & EPG Guide:** Smooth channel streaming with an integrated slide-out EPG Channel Guide drawer, channel number badges, recent channels memory, and quick category filtering.
  * **Favorites System:** 1-click star bookmarking for channels, movies, and TV series, stored locally and accessible instantly from the central dashboard.
  * **Watched History & Progress Tracking:** Automatic detection marking movies and episodes as watched (`[ VISTO ]`) upon reaching $\ge 90\%$ playback or completion, with full manual checkmark toggles.
  * **Continue Watching:** Persistent local watch history powered by local storage. Displays remaining time badges (`[ X MIN REMAINING ]`), Electric Blue playback progress bars, and instant 1-click resume from the exact second you left off.
  * **Central Dashboard:** Active account connection monitor, live active/max connection counters, and technical Bento navigation tiles.

* **10-Foot UI & TV Remote Control Ready (Firestick, Android TV, TV Box):**
  * **100% D-Pad Directional Navigation:** Every screen, modal, drawer, and player control is fully navigable using standard TV remotes (Up, Down, Left, Right, OK/Select, Back).
  * **Neon Focus Ring:** Interactive elements highlight with high-contrast Electric Blue borders and neon glow for optimal visibility at 3 meters (10-foot experience).
  * **Non-Blocking Traversal:** Prevents root focus lockouts and eliminates lost cursors across wide gaps and top bars.
  * **Persistent Modals & Back Button:** Protected back-button handling with `PopScope` to prevent dialog flicker on TV remote KeyUp.

* **Internationalization (i18n):**
  * Native support for 3 languages: **Português (`pt_BR`)**, **English (`en_US`)**, and **Español (`es_ES`)**.
  * Instant language switching from Settings without restarting the app.

* **High-Performance Video Engine (libmpv / media_kit):**
  * Minimalist OSD (On-Screen Display) with automatic inactivity hide.
  * **Dedicated Volume Control:** Interactive on-screen slider, dedicated keyboard hotkeys, and smooth pointer mouse-wheel adjustment.
  * **Dynamic Hardware / Software Decoder Switcher:** Tailored for modern Linux workstations (including **Wayland + Nvidia** setups), defaulting to safe software decoding (`hwdec=no`) to eliminate blue-screen or OpenGL context glitches, with on-the-fly toggling between `SW Safe`, `Auto-Copy`, and `HW Direct`.
  * **Pro IPTV Player User-Agent:** Transparent simulation of standard IPTV player headers (`IPTVSmartersPro/3.1.5`) to circumvent provider-side stream throttling and blockades.

* **Smart Authentication & Session Management:**
  * **Auto-Login & Remember Credentials:** Optional persistent session storage via local secure preferences.
  * **URL Normalizer:** Seamless handling of trailing slashes (`/`, `///`), auto-prefixing missing `http://`, and automatic stripping of mistakenly pasted file endpoints (e.g. `/player_api.php` or `/get.php`).
  * Server host and username pre-filled even after manual logout for rapid re-entry.

---

## CONTROLS & NAVIGATION (DESKTOP & TV REMOTE).

When playing media or navigating the app:

| Action | Desktop Keyboard | TV Remote (D-Pad) |
| :--- | :--- | :--- |
| **Play / Pause** | `Space` / `K` | `OK` / `Select` |
| **Seek Forward (+10s)** | `Right Arrow →` | `D-Pad Right →` *(on timeline or +10s button)* |
| **Seek Backward (-10s)** | `Left Arrow ←` | `D-Pad Left ←` *(on timeline or -10s button)* |
| **Volume Up / Down** | `Up Arrow ↑` / `Down Arrow ↓` | Remote Volume Keys / Bottom controls |
| **Next Episode / Channel** | `N` | `D-Pad` to Next button |
| **Previous Episode / Channel**| `P` | `D-Pad` to Previous button |
| **Mute / Unmute** | `M` | `D-Pad` to Mute button |
| **Cycle HW/SW Decoder** | `D` | `D-Pad` to Decoder badge |
| **Exit / Return** | `ESC` | `Back` button |
| **Navigate Controls** | `Tab` / Arrow Keys | `D-Pad` Directional Keys |

---

## ARCHITECTURE.

The codebase strictly adheres to **Clean Architecture** with a **Feature-First** structure:

```
lib/
├── core/
│   ├── localization/                  # AppLocalizations, LocaleProvider (pt_BR, en_US, es_ES)
│   ├── models/                        # Common domain models
│   ├── services/                      # Background utilities & helpers
│   ├── storage/                       # Local persistence services:
│   │   ├── watch_history_service.dart # Continue watching & resume positions
│   │   ├── favorites_service.dart     # Starred channels, movies & series
│   │   ├── recent_channels_service.dart# Recently watched Live TV channels
│   │   └── watched_service.dart       # Watched status tracker
│   ├── theme/                         # Design tokens (Canvas #0D1216, Bento #141A1F, Electric Blue #0A84FF)
│   ├── utils/                         # Fuzzy search, text formatters & network helpers
│   └── widgets/                       # Reusable brutalist UI components:
│       ├── bento_card.dart            # Interactive modular Bento cards
│       ├── brutalist_button.dart      # High-contrast action buttons
│       ├── hanko_badge.dart           # Japanese Hanko status tags
│       ├── hanko_loader.dart          # Kanji-inspired animated loaders
│       ├── quick_filter_bar.dart      # Category chips with remote autofocus
│       └── tech_crosses.dart          # Technical crosshair accents (+ + +)
├── features/
│   ├── auth/                          # Xtream authentication, account state & URL sanitization
│   ├── dashboard/                     # Central Hub, Continue Watching row & live stats
│   ├── vod/                           # Movies catalog, search, filters & details
│   ├── series/                        # Series catalog, seasons, episodes & countdown card
│   ├── live/                          # Live channels, categories & EPG Guide panel
│   ├── favorites/                     # Bookmarked media management
│   ├── history/                       # Full watch history timeline
│   ├── settings/                      # Language selector, cache cleaner & stream formats
│   └── player/                        # media_kit (libmpv) video player with TV D-Pad traversal
└── main.dart                          # App initialization, Providers & system orientation setup
```

---

## DEVELOPMENT & RUNNING.

### Prerequisites:
* **Flutter SDK:** `>= 3.10.0`
* **Linux (Arch, Ubuntu, Fedora):** System-level `mpv` and `libmpv` packages:
  ```bash
  # Arch Linux / Manjaro / CachyOS
  sudo pacman -S mpv
  
  # Ubuntu / Debian / Pop!_OS
  sudo apt install libmpv-dev mpv
  
  # Fedora
  sudo dnf install mpv-libs-devel mpv
  ```

### Running on Linux Desktop:
```bash
flutter run -d linux
```

### Running on Android:
Connect your Android phone or TV box with USB debugging enabled, then execute:
```bash
flutter run
```

### Hot Reload Keybindings:
* Press **`r`** in the terminal for instant **Hot Reload**.
* Press **`R`** for a full **Hot Restart**.
* Press **`q`** to quit the session.

---

## RELEASES & PACKAGING.

### Official Landing Page (Web):
For visual installation guides, direct APK downloads, Linux AppImage/tarball links, and TV Box / Firestick setup instructions, visit:  
👉 **[satodu.github.io/panda-iptv](https://satodu.github.io/panda-iptv/)**

### Arch User Repository (AUR):
Panda IPTV is officially available on the Arch User Repository (AUR) as [`panda-iptv-bin`](https://aur.archlinux.org/packages/panda-iptv-bin).

Install directly with your preferred AUR helper:
```bash
paru -S panda-iptv-bin
# or
yay -S panda-iptv-bin
```
The packaging template is maintained under `packaging/aur/PKGBUILD`.

### Android APK & TV Downloader (Android TV / Fire TV Stick):
You can download the APK directly or install it on your TV / Fire TV Stick using the **Downloader by AFTVnews** app:
* **Downloader Code (AFTV):**  
  👉 **`9916531`** (type this 7-digit code into the Downloader app URL bar)
* **Direct URL (Always latest release):**  
  `https://github.com/satodu/panda-iptv/releases/latest/download/Panda-IPTV.apk`
* **Short Web Link:**  
  [https://aftv.news/9916531](https://aftv.news/9916531)
* **How to Install via Downloader App:**  
  1. Open the **Downloader** app on your Android TV or Fire TV Stick.
  2. Type the code **`9916531`** and press **Go**.
  3. The APK will download and trigger the Android installer automatically.

### Windows Desktop (Portable Bundle x64):
Download the portable bundle directly from [GitHub Releases](https://github.com/satodu/panda-iptv/releases/latest):
* `Panda-IPTV-<version>-windows-x64.zip` (extract and run `panda_iptv.exe`)

### Linux AppImage & Tarball (Manual Local Build):
Build universal standalone Linux packages locally with the included release script:
```bash
bash scripts/build_release.sh
```
Artifacts are automatically produced inside the `dist/` directory:
* `dist/Panda-IPTV-<version>-x86_64.AppImage` (Universal portable Linux executable)
* `dist/panda-iptv-<version>-linux-x64.tar.gz` (Standalone tarball bundle)

### CI/CD Automated Releases (GitHub Actions):
Releases are automated via GitHub Actions (`.github/workflows/release.yml`). Pushing a version tag builds all artifacts and publishes them to GitHub Releases:
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## SUPPORT THE PROJECT (KO-FI).

If you enjoy **Panda IPTV** and would like to support ongoing development:

<p align="center">
  <a href="https://ko-fi.com/retro_panda" target="_blank">
    <img src="https://storage.ko-fi.com/cdn/kofi3.png?v=3" height="38" alt="Support on Ko-fi" />
  </a>
</p>

☕ **Support at:** [ko-fi.com/retro_panda](https://ko-fi.com/retro_panda)

---

## LICENSE & TERMS OF USE.

Distributed under the **MIT License** with an explicit Anti-Piracy Addendum. See the full [`LICENSE`](file:///run/media/panda/panda/Projects/satodu/panda-iptv/LICENSE) file for complete details.

```
Panda IPTV is strictly an independent client video player.
It does not supply, broadcast, host, or condone unauthorized access to media streams.
```

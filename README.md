<p align="center">
  <img src="assets/images/logo.png" width="160" height="160" alt="Panda IPTV Logo" style="border-radius: 24px;" />
</p>

<h1 align="center">PANDA IPTV.</h1>

<p align="center">
  <b>Modern IPTV Multimedia Player with Oriental Minimalist Brutalism Design.</b><br/>
  Engineered with Flutter for <b>Linux Desktop</b> and <b>Android</b>, powered by native <b>libmpv</b> video acceleration.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Linux_Desktop-%23FCC624.svg?style=for-the-badge&logo=linux&logoColor=black" alt="Linux Desktop" />
  <img src="https://img.shields.io/badge/Android-%233DDC84.svg?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Player-libmpv-0A84FF?style=for-the-badge" alt="libmpv" />
  <img src="https://img.shields.io/badge/Design-Oriental_Brutalism-0D1216?style=for-the-badge&labelColor=0A84FF" alt="Oriental Brutalism" />
  <a href="https://ko-fi.com/retro_panda" target="_blank"><img src="https://img.shields.io/badge/Ko--fi-Support_the_Project-%23FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Ko-fi" /></a>
</p>

---

## OVERVIEW.

**Panda IPTV** is a high-performance multimedia center designed for streaming playlists and on-demand content through the **Xtream Codes API** protocol. Breaking away from generic IPTV templates, Panda introduces a signature **Oriental Minimalist Brutalism** design language: bold geometric uppercase typography with abrupt periods, modular Bento grid layouts with balanced spatial breathing room (*the Japanese aesthetic concept 'Ma'*), and surgical accents in **Electric Blue** (`#0A84FF`).

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
  * **Movies (VOD):** Comprehensive catalog with real-time instant search, category filters (defaulting to `ALL`), high-resolution posters, plot synopses, cast, director, release year, age rating, and watched markers.
  * **Series & Binge-Watching:** Full season and episode hierarchy, runtimes, next/previous episode transitions, and automatic 6-second countdown cards to play next episodes seamlessly.
  * **Favorites System:** 1-click star bookmarking for channels, movies, and TV series, stored locally and accessible instantly from the central dashboard.
  * **Watched History & Progress Tracking:** Automatic detection marking movies and episodes as watched (`[ VISTO ]`) upon reaching $\ge 90\%$ playback or completion, with full manual checkmark toggles.
  * **Continue Watching:** Persistent local watch history powered by local storage. Displays remaining time badges (`[ X MIN REMAINING ]`), Electric Blue playback progress bars, and instant 1-click resume from the exact second you left off.
  * **Live TV:** Stream navigation and playback via Xtream Codes protocol.
  * **Central Dashboard:** Active account connection monitor, live active/max connection counters, and technical Bento navigation tiles.

* **High-Performance Video Engine (libmpv):**
  * Minimalist OSD (On-Screen Display) with automatic inactivity hide.
  * **Dedicated Volume Control:** Interactive on-screen slider, dedicated keyboard hotkeys, and smooth pointer mouse-wheel adjustment.
  * **Dynamic Hardware / Software Decoder Switcher:** Tailored for modern Linux workstations (including **Wayland + Nvidia** setups), defaulting to safe software decoding (`hwdec=no`) to eliminate blue-screen or OpenGL context glitches, with on-the-fly toggling between `SW Safe`, `Auto-Copy`, and `HW`.
  * **Pro IPTV Player User-Agent:** Transparent simulation of standard IPTV player headers (`IPTVSmartersPro/3.1.5`) to circumvent provider-side stream throttling and blockades.

* **Smart Authentication & Session Management:**
  * **Auto-Login & Remember Credentials:** Optional persistent session storage via encrypted/local preferences.
  * **URL Normalizer:** Seamless handling of trailing slashes (`/`, `///`), auto-prefixing missing `http://`, and automatic stripping of mistakenly pasted file endpoints (e.g. `/player_api.php` or `/get.php`).
  * Server host and username pre-filled even after manual logout for rapid re-entry.

* **Fully Responsive & TV Remote Ready:**
  * Smooth adaptive layout supporting **Desktop Landscape** (Linux workstation / HTPC) and **Mobile Portrait / Landscape** (Android smartphones, tablets, and TV boxes).
  * Optimized D-Pad navigation with auto-scroll focus for TV remotes.

---

## PLAYER KEYBOARD SHORTCUTS.

When playing any movie, episode, or stream on Desktop:

| Key / Action | Function |
| :--- | :--- |
| **Space** | Play / Pause |
| **Right Arrow $\rightarrow$** | Seek forward 10 seconds (`+10s`) |
| **Left Arrow $\leftarrow$** | Seek backward 10 seconds (`-10s`) |
| **Up Arrow $\uparrow$** | Volume up (+5%) |
| **Down Arrow $\downarrow$** | Volume down (-5%) |
| **Mouse Wheel** | Adjust volume up / down at cursor position |
| **N / Next Track** | Skip to next episode in playlist |
| **P / Previous Track** | Return to previous episode in playlist |
| **M** | Toggle Mute / Unmute audio |
| **D** | Cycle decoding mode (`Safe SW` / `Auto-Copy` / `HW`) |
| **ESC** | Exit player and return to media details |

---

## ARCHITECTURE (CLEAN ARCHITECTURE / FEATURE-FIRST).

```
lib/
├── core/
│   ├── storage/
│   │   ├── watch_history_item.dart    # Watch history data model
│   │   └── watch_history_service.dart # Local history persistence & reactive notifier
│   ├── theme/
│   │   ├── app_colors.dart            # Design tokens (Mineral Black, Electric Blue, Cyan)
│   │   ├── app_theme.dart             # Brutalist dark theme
│   │   └── app_typography.dart        # Space Grotesk + JetBrains Mono + Noto Sans JP
│   └── widgets/
│       ├── bento_card.dart            # Interactive modular Bento cards
│       ├── brutalist_button.dart      # Electric Blue action buttons
│       ├── hanko_badge.dart           # Japanese Hanko status badges & tags
│       └── tech_crosses.dart          # Technical crosshair accents (+ + +)
├── features/
│   ├── auth/                          # Xtream authentication, account models & URL sanitization
│   ├── dashboard/                     # Central Hub, Continue Watching row & Bento grid
│   ├── vod/                           # VOD movie catalog, category filters & details
│   ├── series/                        # Series catalog, seasons, episodes & details
│   └── player/                        # libmpv media player with custom OSD & volume control
└── main.dart                          # Native dependency initialization & Provider wiring
```

---

## DEVELOPMENT & RUNNING.

### Prerequisites:
* **Flutter SDK:** `>= 3.10.0`
* **Linux (Arch, Ubuntu, Fedora):** System-level `mpv` and `libmpv` packages:
  ```bash
  # Arch Linux
  sudo pacman -S mpv
  
  # Ubuntu / Debian
  sudo apt install libmpv-dev mpv
  
  # Fedora
  sudo dnf install mpv-libs-devel mpv
  ```

### Running on Linux Desktop:
```bash
flutter run -d linux
```

### Running on Android:
Connect your Android phone or emulator with USB debugging enabled, then execute:
```bash
flutter run
```

### Hot Reload Keybindings:
* Press **`r`** in the terminal for instant **Hot Reload**.
* Press **`R`** for a full **Hot Restart**.
* Press **`q`** to quit the session.

---

## RELEASES & PACKAGING.

### CI/CD Automated Releases (GitHub Actions):
Whenever you push a version tag (e.g. `v0.0.1`, `v1.0.0`), a GitHub Action workflow automatically builds the Linux AppImage, `.tar.gz`, and Android APK, then publishes them directly as downloadable assets on GitHub Releases:
```bash
git tag v0.0.1
git push origin v0.0.1
```

### Linux AppImage & Tarball (Manual):
Build universal standalone Linux packages locally with the included release script:
```bash
bash scripts/build_release.sh
```
Artifacts are automatically produced inside the `dist/` directory:
* `dist/Panda-IPTV-<version>-x86_64.AppImage` (Universal portable Linux executable)
* `dist/panda-iptv-<version>-linux-x64.tar.gz` (Standalone tarball bundle)

### Arch User Repository (AUR):
An official `PKGBUILD` template is available in `packaging/aur/PKGBUILD` for publishing to the AUR (`panda-iptv-bin`).

### Android APK & TV Downloader (Android TV / Fire Stick):
You can download the APK directly or install it on your TV / Fire TV Stick using the **Downloader by AFTVnews** app:
* **Downloader Code (AFTV):**  
  👉 **`9916531`** (type this 7-digit code into the Downloader app URL bar)
* **Direct URL (Always latest release):**  
  `https://github.com/satodu/panda-iptv/releases/latest/download/Panda-IPTV.apk`
* **Short Web Link:**  
  [https://aftv.news/9916531](https://aftv.news/9916531)
* **How to Install via Downloader App:**  
  1. Open the **Downloader** app on your Android TV or Fire TV Stick.
  2. Type the code **`9916531`** (or the direct URL above) and press **Go**.
  3. The APK will download and trigger the Android installer automatically.

### Android APK Release (Manual Build):
To compile the release APK locally:
```bash
flutter build apk --release
```
Or generate optimized per-architecture APKs (arm64-v8a, armeabi-v7a, x86_64):
```bash
flutter build apk --release --split-per-abi
```
Generated APK outputs will be placed in `build/app/outputs/flutter-apk/`.

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


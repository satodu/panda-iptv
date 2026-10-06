# GUIA DE INTERNACIONALIZAÇÃO // PANDA IPTV (i18n)
> Manual de Internacionalização e Diretrizes de Tradução para Agentes de IA e Desenvolvedores

O Panda IPTV utiliza um sistema nativo e leve de internacionalização baseado em arquivos JSON sob `assets/i18n/`.

---

## 1. Idiomas Suportados

| Código | Idioma | Arquivo JSON | Padrão |
| :--- | :--- | :--- | :--- |
| `pt_BR` | Português (Brasil) | [`assets/i18n/pt_BR.json`](file:///home/panda/orca/workspaces/panda-iptv/fiddler/assets/i18n/pt_BR.json) | Sim (Fallback) |
| `en_US` | Inglês (EUA) | [`assets/i18n/en_US.json`](file:///home/panda/orca/workspaces/panda-iptv/fiddler/assets/i18n/en_US.json) | Alternativo |
| `es_ES` | Espanhol | [`assets/i18n/es_ES.json`](file:///home/panda/orca/workspaces/panda-iptv/fiddler/assets/i18n/es_ES.json) | Alternativo |

---

## 2. Como Usar no Código (Flutter / Dart)

### A. Acesso Direto via Context Extension
A forma recomendada para telas e widgets:
```dart
import '../../core/localization/app_localizations.dart';

// Tradução simples
Text(context.tr('dashboard.welcome_title'))

// Tradução com interpolação de variáveis ({user}, {active}, etc.)
Text(context.tr('dashboard.connection', args: {'user': user.username}))
```

### B. Troca Dinâmica de Idioma via Provider
O estado e persistência do idioma são gerenciados pelo [`LocaleProvider`](file:///home/panda/orca/workspaces/panda-iptv/fiddler/lib/core/localization/locale_provider.dart):
```dart
final localeProv = context.read<LocaleProvider>();

// Métodos rápidos:
await localeProv.setPortuguese();
await localeProv.setEnglish();
await localeProv.setSpanish();

// Ou especificando um Locale:
await localeProv.setLocale(const Locale('en', 'US'));
```

---

## 3. Diretrizes Obrigatórias para Agentes de IA (AI Rules)

1. **PROIBIDO HARDCODED STRINGS**: Toda e qualquer nova string exibida ao usuário deve ser adicionada aos arquivos JSON.
2. **ATUALIZAÇÃO TRIPLA OBRIGATÓRIA**: Ao criar uma nova chave, ela **DEVE ser adicionada simultaneamente** em:
   - `pt_BR.json`
   - `en_US.json`
   - `es_ES.json`
3. **IDENTIDADE VISUAL BRUTALISTA PRESERVADA**:
   - Títulos de seções, cabeçalhos e botões principais **DEVEM estar em CAIXA-ALTA e terminar com PONTO FINAL (.)** em todos os três idiomas:
     - PT: `"AO VIVO."` | EN: `"LIVE TV."` | ES: `"EN VIVO."`
     - PT: `"ASSISTIR AGORA."` | EN: `"WATCH NOW."` | ES: `"REPRODUCIR AHORA."`
4. **NOMENCLATURA DAS CHAVES**:
   - Use hierarquia de escopo com snake_case:
     - `common.retry`
     - `auth.login_button`
     - `dashboard.movies_title`
     - `vod.search_hint`
     - `series.season`
     - `player.playback_failed`
5. **INTERPOLAÇÃO**:
   - Use `{parametro}` no JSON e passe o mapa `args: {'parametro': valor}` no `tr()`.

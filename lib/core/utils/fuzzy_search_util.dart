/// Utilitário de Busca Difusa (Fuzzy Search) de Alta Performance
/// - Normalização de acentos e diacríticos (ex: "cão" == "cao", "Ação" == "acao")
/// - Tolerância a erros de digitação (Levenshtein e correspondência de subsequência)
/// - Busca multi-palavra em qualquer ordem (ex: "aranha homem" acha "Homem-Aranha")
/// - Ranking de relevância com pontuação ponderada (matches exatos no topo)
class FuzzySearchUtil {
  static final RegExp _cleanRegex = RegExp(r'[^a-z0-9\s]');
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  static const Map<String, String> _diacritics = {
    'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  /// Remove acentos e converte para minúsculas
  static String normalize(String input) {
    if (input.isEmpty) return '';
    var text = input.toLowerCase().trim();

    _diacritics.forEach((char, replacement) {
      if (text.contains(char)) {
        text = text.replaceAll(char, replacement);
      }
    });

    return text;
  }

  /// Limpa símbolos e pontuações para tokenização
  static List<String> tokenize(String input) {
    if (input.isEmpty) return const [];
    final clean = normalize(input).replaceAll(_cleanRegex, ' ');
    return clean
        .split(_whitespaceRegex)
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Calcula a distância de Levenshtein entre duas strings
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        final min1 = v1[j] + 1;
        final min2 = v0[j + 1] + 1;
        final min3 = v0[j] + cost;
        v1[j + 1] = min1 < min2 ? (min1 < min3 ? min1 : min3) : (min2 < min3 ? min2 : min3);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

  /// Retorna a pontuação de relevância (score > 0 indica match; maior é melhor)
  static int calculateScore(String rawQuery, String rawTarget) {
    if (rawQuery.trim().isEmpty) return 100;
    if (rawTarget.trim().isEmpty) return 0;

    final normQuery = normalize(rawQuery);
    final queryTokens = tokenize(normQuery);

    return _scoreWithPrecomputed(normQuery, queryTokens, rawTarget);
  }

  static int _scoreWithPrecomputed(String normQuery, List<String> queryTokens, String rawTarget) {
    if (rawTarget.isEmpty) return 0;

    final normTarget = normalize(rawTarget);

    // 1. Match exato idêntico
    if (normTarget == normQuery) {
      return 1000;
    }

    // 2. Prefixo exato no início do título
    if (normTarget.startsWith(normQuery)) {
      return 800;
    }

    // 3. Contém a query inteira de forma contígua
    final contIndex = normTarget.indexOf(normQuery);
    if (contIndex != -1) {
      return 600 - (contIndex * 5).clamp(0, 150);
    }

    if (queryTokens.isEmpty) return 0;

    // Para buscas curtas (1 ou 2 letras), não gasta CPU com loops caros se não foi contíguo
    if (normQuery.length <= 2) return 0;

    // 4. Tokenização e correspondência de palavras (em qualquer ordem)
    final targetTokens = tokenize(normTarget);
    if (targetTokens.isEmpty) return 0;

    int matchedTokensCount = 0;
    int tokenScore = 0;

    for (final qToken in queryTokens) {
      bool tokenMatched = false;

      for (final tToken in targetTokens) {
        // Match exato do token
        if (tToken == qToken) {
          matchedTokensCount++;
          tokenScore += 100;
          tokenMatched = true;
          break;
        }

        // Prefixo do token (ex: "dead" -> "deadpool")
        if (tToken.startsWith(qToken)) {
          matchedTokensCount++;
          tokenScore += 80;
          tokenMatched = true;
          break;
        }

        // Contém o token
        if (tToken.contains(qToken)) {
          matchedTokensCount++;
          tokenScore += 60;
          tokenMatched = true;
          break;
        }

        // Tolerância Fuzzy para pequenos erros de digitação (Levenshtein)
        if (qToken.length >= 4 && tToken.length >= 4) {
          final maxAllowedDistance = qToken.length <= 5 ? 1 : 2;
          final dist = levenshteinDistance(qToken, tToken);
          if (dist <= maxAllowedDistance) {
            matchedTokensCount++;
            tokenScore += 45 - (dist * 10);
            tokenMatched = true;
            break;
          }
        }
      }

      if (!tokenMatched) {
        if (qToken.length <= 3) return 0;
      }
    }

    if (matchedTokensCount == queryTokens.length) {
      return 400 + tokenScore;
    }

    if (queryTokens.length >= 3 && (matchedTokensCount / queryTokens.length) >= 0.75) {
      return 200 + tokenScore;
    }

    // 5. Match difuso na string completa para consultas de uma palavra com erro leve
    if (queryTokens.length == 1) {
      final qToken = queryTokens.first;
      if (qToken.length >= 4) {
        for (final tToken in targetTokens) {
          final maxAllowed = qToken.length <= 5 ? 1 : 2;
          if (levenshteinDistance(qToken, tToken) <= maxAllowed) {
            return 150;
          }
        }
      }
    }

    return 0;
  }

  /// Verifica se o alvo atende à consulta
  static bool matches(String query, String target) {
    return calculateScore(query, target) > 0;
  }

  /// Filtra e ordena uma lista de itens pelo ranking de relevância com alta performance
  static List<T> search<T>({
    required String query,
    required List<T> items,
    required String Function(T) titleSelector,
    String Function(T)? secondarySelector,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return items;

    final normQuery = normalize(trimmed);
    if (normQuery.isEmpty) return items;
    final queryTokens = tokenize(normQuery);

    final List<MapEntry<T, int>> scored = [];

    for (final item in items) {
      final title = titleSelector(item);
      var score = _scoreWithPrecomputed(normQuery, queryTokens, title);

      if (score == 0 && secondarySelector != null) {
        final secondary = secondarySelector(item);
        if (secondary.isNotEmpty) {
          final secScore = _scoreWithPrecomputed(normQuery, queryTokens, secondary);
          if (secScore > 0) {
            score = secScore ~/ 2;
          }
        }
      }

      if (score > 0) {
        scored.add(MapEntry(item, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }
}

enum ContentSortOption {
  recentYear,     // Ano de lançamento (mais novo para mais antigo)
  addedServer,    // Novidades do servidor do provedor (campo 'added' decrescente)
  rating,         // Melhor nota / avaliação
  alphaAsc,       // A - Z
  alphaDesc,      // Z - A
}

enum ContentAudioOption {
  all,
  dubbed,         // Dublado ([DUB], DUBLADO)
  subtitled,      // Legendado ([LEG], LEGENDADO)
}

enum ContentQualityOption {
  all,
  q4k,            // 4K / UHD
  qFhd,           // 1080p / FHD
  qHd,            // 720p / HD
}

enum ContentWatchedOption {
  all,
  unwatched,      // Não assistidos
  watched,        // Já assistidos
}

enum LiveSortOption {
  defaultProvider,// Ordem padrão do servidor
  channelNumber,  // Por número (#001, #002)
  alphaAsc,       // A - Z
}

enum LiveFilterOption {
  all,
  recent,         // Assistidos recentemente
  withEpg,        // Apenas canais com guia EPG
  q4k,            // 4K
  qFhd,           // FHD
  qHd,            // HD
}

class ContentFilterState {
  final ContentSortOption sortOption;
  final ContentAudioOption audioOption;
  final ContentQualityOption qualityOption;
  final ContentWatchedOption watchedOption;
  final bool onlyRecentReleases; // Apenas lançamentos recentes (ano >= 2024 ou tag lançamento)
  final String? genre;           // Gênero / Estilo ('all', 'Ação', 'Comédia', etc.)

  const ContentFilterState({
    this.sortOption = ContentSortOption.recentYear,
    this.audioOption = ContentAudioOption.all,
    this.qualityOption = ContentQualityOption.all,
    this.watchedOption = ContentWatchedOption.all,
    this.onlyRecentReleases = false,
    this.genre,
  });

  bool get hasActiveFilters {
    return sortOption != ContentSortOption.recentYear ||
        audioOption != ContentAudioOption.all ||
        qualityOption != ContentQualityOption.all ||
        watchedOption != ContentWatchedOption.all ||
        onlyRecentReleases ||
        (genre != null && genre != 'all');
  }

  int get activeFiltersCount {
    int count = 0;
    if (sortOption != ContentSortOption.recentYear) count++;
    if (audioOption != ContentAudioOption.all) count++;
    if (qualityOption != ContentQualityOption.all) count++;
    if (watchedOption != ContentWatchedOption.all) count++;
    if (onlyRecentReleases) count++;
    if (genre != null && genre != 'all') count++;
    return count;
  }

  ContentFilterState copyWith({
    ContentSortOption? sortOption,
    ContentAudioOption? audioOption,
    ContentQualityOption? qualityOption,
    ContentWatchedOption? watchedOption,
    bool? onlyRecentReleases,
    String? genre,
  }) {
    return ContentFilterState(
      sortOption: sortOption ?? this.sortOption,
      audioOption: audioOption ?? this.audioOption,
      qualityOption: qualityOption ?? this.qualityOption,
      watchedOption: watchedOption ?? this.watchedOption,
      onlyRecentReleases: onlyRecentReleases ?? this.onlyRecentReleases,
      genre: genre ?? this.genre,
    );
  }

  static const List<String> standardGenres = [
    'all',
    'Ação',
    'Comédia',
    'Terror',
    'Suspense',
    'Ficção Científica',
    'Animação',
    'Aventura',
    'Drama',
    'Romance',
    'Documentário',
    'Policial',
    'Família',
  ];

  static const ContentFilterState initial = ContentFilterState();
}

class LiveFilterState {
  final LiveSortOption sortOption;
  final LiveFilterOption filterOption;

  const LiveFilterState({
    this.sortOption = LiveSortOption.defaultProvider,
    this.filterOption = LiveFilterOption.all,
  });

  bool get hasActiveFilters =>
      sortOption != LiveSortOption.defaultProvider ||
      filterOption != LiveFilterOption.all;

  int get activeFiltersCount {
    int count = 0;
    if (sortOption != LiveSortOption.defaultProvider) count++;
    if (filterOption != LiveFilterOption.all) count++;
    return count;
  }

  LiveFilterState copyWith({
    LiveSortOption? sortOption,
    LiveFilterOption? filterOption,
  }) {
    return LiveFilterState(
      sortOption: sortOption ?? this.sortOption,
      filterOption: filterOption ?? this.filterOption,
    );
  }

  static const LiveFilterState initial = LiveFilterState();
}

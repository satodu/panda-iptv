import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panda_iptv/core/storage/favorite_item.dart';
import 'package:panda_iptv/core/storage/favorites_service.dart';
import 'package:panda_iptv/core/storage/recent_channels_service.dart';
import 'package:panda_iptv/features/auth/models/xtream_account.dart';
import 'package:panda_iptv/features/live/data/live_service.dart';
import 'package:panda_iptv/features/live/models/live_category.dart';
import 'package:panda_iptv/features/live/models/live_stream_item.dart';
import 'package:panda_iptv/features/live/presentation/live_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final mockAccount = XtreamAccount(
    serverUrl: 'http://iptv.example.com:8080',
    username: 'user123',
    password: 'pass123',
    userInfo: XtreamUserInfo(
      username: 'user123',
      status: 'Active',
      expDate: '',
      isTrial: false,
      activeCons: '1',
      maxConnections: '2',
    ),
    serverInfo: XtreamServerInfo(
      url: 'http://iptv.example.com',
      port: '8080',
      httpsPort: '443',
      serverProtocol: 'http',
      timezone: 'UTC',
    ),
  );

  group('LiveCategory model', () {
    test('converte JSON corretamente', () {
      final json = {
        'category_id': '10',
        'category_name': 'ESPORTES',
        'parent_id': 0,
      };

      final cat = LiveCategory.fromJson(json);
      expect(cat.categoryId, '10');
      expect(cat.categoryName, 'ESPORTES');
      expect(cat.parentId, 0);
    });

    test('lida com campos nulos e fallbacks', () {
      final cat = LiveCategory.fromJson({});
      expect(cat.categoryId, '');
      expect(cat.categoryName, 'Sem Categoria');
      expect(cat.parentId, 0);
    });
  });

  group('LiveStreamItem model', () {
    test('converte JSON com formatação de canal e resolução', () {
      final json = {
        'num': 7,
        'name': 'ESPN BRASIL 4K',
        'stream_type': 'live',
        'stream_id': 1054,
        'stream_icon': 'http://image.com/espn.png',
        'epg_channel_id': 'espn.br',
        'category_id': '10',
      };

      final item = LiveStreamItem.fromJson(json, categoryName: 'ESPORTES');
      expect(item.streamId, 1054);
      expect(item.name, 'ESPN BRASIL 4K');
      expect(item.formattedNumber, '#007');
      expect(item.resolutionTag, '4K');
      expect(item.categoryName, 'ESPORTES');
    });

    test('detecta resoluções FHD, HD e SD', () {
      final itemFhd = LiveStreamItem.fromJson({'num': 1, 'name': 'GLOBO FHD', 'stream_id': 1, 'category_id': '1'});
      final itemHd = LiveStreamItem.fromJson({'num': 2, 'name': 'GLOBO 720P HD', 'stream_id': 2, 'category_id': '1'});
      final itemSd = LiveStreamItem.fromJson({'num': 3, 'name': 'GLOBO SD 480', 'stream_id': 3, 'category_id': '1'});
      final itemLive = LiveStreamItem.fromJson({'num': 4, 'name': 'CANAL COMUM', 'stream_id': 4, 'category_id': '1'});

      expect(itemFhd.resolutionTag, 'FHD');
      expect(itemHd.resolutionTag, 'HD');
      expect(itemSd.resolutionTag, 'SD');
      expect(itemLive.resolutionTag, 'LIVE');
    });
  });

  group('LiveService', () {
    test('gera URL de stream TS compatível com Xtream Codes', () {
      final service = LiveService();
      final url = service.buildStreamUrl(mockAccount, 1054);
      expect(url, 'http://iptv.example.com:8080/live/user123/pass123/1054.ts');
    });
  });

  group('LiveProvider', () {
    test('filtra canais por busca de texto', () {
      final provider = LiveProvider();
      expect(provider.filteredChannels, isEmpty);

      provider.setSearchQuery('espn');
      expect(provider.searchQuery, 'espn');
    });
  });

  group('RecentChannelsService', () {
    test('registra canal assistido e atualiza ordem ao assistir novamente', () async {
      await RecentChannelsService.clear();

      await RecentChannelsService.recordChannelWatched(
        streamId: 101,
        name: 'GLOBO SP',
        categoryName: 'ABERTOS',
        channelNumber: '#001',
        streamUrl: 'http://example.com/101.ts',
      );

      await RecentChannelsService.recordChannelWatched(
        streamId: 102,
        name: 'SBT HD',
        categoryName: 'ABERTOS',
        channelNumber: '#002',
        streamUrl: 'http://example.com/102.ts',
      );

      var channels = await RecentChannelsService.loadChannels();
      expect(channels.length, 2);
      expect(channels.first.streamId, 102);

      // Re-assistir o canal 101 deve movê-lo para o topo sem duplicar
      await RecentChannelsService.recordChannelWatched(
        streamId: 101,
        name: 'GLOBO SP',
        categoryName: 'ABERTOS',
        channelNumber: '#001',
        streamUrl: 'http://example.com/101.ts',
      );

      channels = await RecentChannelsService.loadChannels();
      expect(channels.length, 2);
      expect(channels.first.streamId, 101);

      // Remover canal
      await RecentChannelsService.removeChannel(101);
      channels = await RecentChannelsService.loadChannels();
      expect(channels.length, 1);
      expect(channels.first.streamId, 102);
    });
  });

  group('FavoritesService com canais ao vivo', () {
    test('permite favoritar e desfavoritar canais live', () async {
      await FavoritesService.clearFavorites();

      final favLive = FavoriteItem(
        id: 'live_500',
        title: 'HBO MAX LIVE',
        type: 'live',
        cover: 'http://logo.com/hbo.png',
        genre: 'FILMES',
        streamUrl: 'http://example.com/500.ts',
        channelNumber: '#500',
        addedAt: DateTime.now(),
      );

      final added = await FavoritesService.toggleFavorite(favLive);
      expect(added, isTrue);
      expect(FavoritesService.isFavoriteSync('live_500'), isTrue);

      final removed = await FavoritesService.toggleFavorite(favLive);
      expect(removed, isFalse);
      expect(FavoritesService.isFavoriteSync('live_500'), isFalse);
    });
  });
}

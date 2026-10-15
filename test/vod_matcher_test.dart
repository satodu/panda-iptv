import 'package:flutter_test/flutter_test.dart';
import 'package:panda_iptv/features/vod/models/vod_item.dart';
import 'package:panda_iptv/features/vod/utils/vod_matcher.dart';

void main() {
  group('VodMatcher Tests', () {
    final catalog = [
      const VodItem(
        streamId: 3506104,
        name: 'Nó',
        categoryId: '746',
      ),
      const VodItem(
        streamId: 3441432,
        name: 'Soldado Universal: O Retorno (1999)',
        categoryId: '741',
        releaseDate: '1999',
      ),
      const VodItem(
        streamId: 3441400,
        name: 'Soldado Universal (1992)',
        categoryId: '741',
        releaseDate: '1992',
      ),
      const VodItem(
        streamId: 100,
        name: 'Up: Altas Aventuras [FHD]',
        categoryId: '10',
        releaseDate: '2009',
      ),
    ];

    test('Nunca deve dar match com "Nó" quando o filme for "Soldado Universal: O Retorno"', () {
      final match = VodMatcher.findBestMatch(
        tmdbTitle: 'Soldado Universal: O Retorno',
        tmdbReleaseDate: '1999-08-20',
        iptvCatalog: catalog,
      );

      expect(match, isNotNull);
      expect(match!.streamId, equals(3441432));
      expect(match.name, contains('Soldado Universal: O Retorno'));
    });

    test('Deve dar match com "Nó" apenas quando o título for exatamente "Nó"', () {
      final match = VodMatcher.findBestMatch(
        tmdbTitle: 'Nó',
        iptvCatalog: catalog,
      );

      expect(match, isNotNull);
      expect(match!.streamId, equals(3506104));
    });

    test('Não deve dar match com filmes aleatórios para títulos curtos inexistentes', () {
      final match = VodMatcher.findBestMatch(
        tmdbTitle: 'It',
        iptvCatalog: catalog,
      );

      expect(match, isNull);
    });

    test('Deve ignorar tags técnicas como [FHD] e encontrar "Up: Altas Aventuras"', () {
      final match = VodMatcher.findBestMatch(
        tmdbTitle: 'Up: Altas Aventuras',
        tmdbReleaseDate: '2009-05-29',
        iptvCatalog: catalog,
      );

      expect(match, isNotNull);
      expect(match!.streamId, equals(100));
    });
  });
}

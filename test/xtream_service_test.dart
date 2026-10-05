import 'package:flutter_test/flutter_test.dart';
import 'package:panda_iptv/features/auth/data/xtream_service.dart';

void main() {
  group('XtreamService.formatServerUrl', () {
    test('trata URL com barra no final', () {
      expect(
        XtreamService.formatServerUrl('http://exemplo.com:8080/'),
        'http://exemplo.com:8080',
      );
    });

    test('trata URL sem barra no final', () {
      expect(
        XtreamService.formatServerUrl('http://exemplo.com:8080'),
        'http://exemplo.com:8080',
      );
    });

    test('trata URL com múltiplas barras no final', () {
      expect(
        XtreamService.formatServerUrl('http://exemplo.com:8080///'),
        'http://exemplo.com:8080',
      );
    });

    test('adiciona http:// caso não haja protocolo', () {
      expect(
        XtreamService.formatServerUrl('exemplo.com:8080/'),
        'http://exemplo.com:8080',
      );
    });

    test('mantém https:// quando fornecido', () {
      expect(
        XtreamService.formatServerUrl('https://exemplo.com:8080/'),
        'https://exemplo.com:8080',
      );
    });

    test('remove sufixo /player_api.php acidentalmente colado', () {
      expect(
        XtreamService.formatServerUrl('http://exemplo.com:8080/player_api.php'),
        'http://exemplo.com:8080',
      );
    });

    test('remove sufixo /get.php acidentalmente colado', () {
      expect(
        XtreamService.formatServerUrl('http://exemplo.com:8080/get.php'),
        'http://exemplo.com:8080',
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  group('XtreamService.login error handling', () {
    test('lança AuthException amigável quando servidor retorna HTML (XUI.one debug mode)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><head><title>XUI.one - Debug Mode</title></head><body>Error</body></html>',
          200,
        );
      });

      final service = XtreamService(client: mockClient);

      expect(
        () => service.login(
          serverUrl: 'http://painel.xyz:8080',
          username: 'teste',
          password: '123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.key,
          'key',
          'auth.invalid_credentials_or_server',
        )),
      );
    });

    test('lança AuthException quando credenciais forem inválidas (auth: 0)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"user_info": {"auth": 0}}',
          200,
        );
      });

      final service = XtreamService(client: mockClient);

      expect(
        () => service.login(
          serverUrl: 'http://painel.xyz:8080',
          username: 'teste',
          password: 'errada',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.key,
          'key',
          'auth.invalid_credentials',
        )),
      );
    });

    test('lança AuthException quando conta estiver desativada (status: Disabled)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"user_info": {"auth": 1, "status": "Disabled"}}',
          200,
        );
      });

      final service = XtreamService(client: mockClient);

      expect(
        () => service.login(
          serverUrl: 'http://painel.xyz:8080',
          username: 'teste',
          password: '123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.key,
          'key',
          'auth.account_disabled',
        )),
      );
    });

    test('lança AuthException quando servidor retornar HTTP 401/403', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      final service = XtreamService(client: mockClient);

      expect(
        () => service.login(
          serverUrl: 'http://painel.xyz:8080',
          username: 'teste',
          password: '123',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.key,
          'key',
          'auth.invalid_credentials',
        )),
      );
    });
  });
}

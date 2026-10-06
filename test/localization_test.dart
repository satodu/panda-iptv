import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('I18n Translation JSONs Integrity', () {
    test('pt_BR.json, en_US.json, and es_ES.json exist and are valid JSON', () {
      final ptFile = File('assets/i18n/pt_BR.json');
      final enFile = File('assets/i18n/en_US.json');
      final esFile = File('assets/i18n/es_ES.json');

      expect(ptFile.existsSync(), isTrue);
      expect(enFile.existsSync(), isTrue);
      expect(esFile.existsSync(), isTrue);

      final Map<String, dynamic> ptMap = json.decode(ptFile.readAsStringSync());
      final Map<String, dynamic> enMap = json.decode(enFile.readAsStringSync());
      final Map<String, dynamic> esMap = json.decode(esFile.readAsStringSync());

      expect(ptMap.containsKey('app_name'), isTrue);
      expect(enMap.containsKey('app_name'), isTrue);
      expect(esMap.containsKey('app_name'), isTrue);

      expect(ptMap['dashboard']['live_title'], 'AO VIVO.');
      expect(enMap['dashboard']['live_title'], 'LIVE TV.');
      expect(esMap['dashboard']['live_title'], 'EN VIVO.');

      expect(ptMap['dashboard']['movies_title'], 'FILMES.');
      expect(enMap['dashboard']['movies_title'], 'MOVIES.');
      expect(esMap['dashboard']['movies_title'], 'PELÍCULAS.');
    });
  });
}

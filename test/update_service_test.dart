import 'package:flutter_test/flutter_test.dart';
import 'package:panda_iptv/core/services/update_service.dart';

void main() {
  group('UpdateService Version Comparison', () {
    test('Correctly identifies newer semver versions', () {
      expect(UpdateService.isNewerVersion('0.0.1', '0.0.2'), isTrue);
      expect(UpdateService.isNewerVersion('0.0.1', '0.1.0'), isTrue);
      expect(UpdateService.isNewerVersion('0.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isNewerVersion('0.0.1+1', 'v0.0.2'), isTrue);
      expect(UpdateService.isNewerVersion('0.0.1-alpha', '0.0.1'), isTrue);
    });

    test('Correctly identifies equal or older versions', () {
      expect(UpdateService.isNewerVersion('0.0.2', '0.0.1'), isFalse);
      expect(UpdateService.isNewerVersion('0.0.1', '0.0.1'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0', '0.9.9'), isFalse);
      expect(UpdateService.isNewerVersion('0.1.0', 'v0.1.0'), isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panda_iptv/core/storage/watch_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await WatchHistoryService.clearHistory();
  });

  test('Series episodes are replaced by the most recent episode watched', () async {
    // 1. Assiste o Episódio 1 da Série A
    await WatchHistoryService.saveProgress(
      id: 'series_101_1',
      title: 'Breaking Bad',
      subtitle: 'TEMP 1 // EP 1 - Pilot',
      streamUrl: 'http://test/1.mkv',
      positionMs: 50000,
      durationMs: 3000000,
      type: 'series',
    );

    var history = await WatchHistoryService.loadHistory();
    expect(history.length, equals(1));
    expect(history.first.title, equals('Breaking Bad'));
    expect(history.first.subtitle, contains('EP 1'));

    // 2. Assiste o Episódio 4 da mesma Série A
    await WatchHistoryService.saveProgress(
      id: 'series_101_4',
      title: 'Breaking Bad',
      subtitle: 'TEMP 1 // EP 4 - Cancer Man',
      streamUrl: 'http://test/4.mkv',
      positionMs: 60000,
      durationMs: 3000000,
      type: 'series',
    );

    history = await WatchHistoryService.loadHistory();
    // Deve conter apenas 1 item para a série Breaking Bad, sendo o Ep 4
    expect(history.length, equals(1));
    expect(history.first.title, equals('Breaking Bad'));
    expect(history.first.subtitle, contains('EP 4'));
    expect(history.first.id, equals('series_101_4'));

    // 3. Assiste um Filme (VOD)
    await WatchHistoryService.saveProgress(
      id: 'vod_999',
      title: 'Interestelar',
      subtitle: '2014',
      streamUrl: 'http://test/movie.mp4',
      positionMs: 45000,
      durationMs: 7200000,
      type: 'movie',
    );

    history = await WatchHistoryService.loadHistory();
    expect(history.length, equals(2));
    expect(history[0].title, equals('Interestelar'));
    expect(history[1].title, equals('Breaking Bad'));
    expect(history[1].subtitle, contains('EP 4'));

    // 4. Assiste o Episódio 2 de OUTRA Série B
    await WatchHistoryService.saveProgress(
      id: 'series_202_2',
      title: 'Severance',
      subtitle: 'TEMP 1 // EP 2',
      streamUrl: 'http://test/sev2.mkv',
      positionMs: 40000,
      durationMs: 3000000,
      type: 'series',
    );

    history = await WatchHistoryService.loadHistory();
    expect(history.length, equals(3));
    expect(history[0].title, equals('Severance'));
    expect(history[1].title, equals('Interestelar'));
    expect(history[2].title, equals('Breaking Bad'));
  });

  test('WatchHistoryService ignores short playback (<10s) and removes finished (>93%)', () async {
    // 1. Playback under 10 seconds is ignored
    await WatchHistoryService.saveProgress(
      id: 'vod_short',
      title: 'Short Movie',
      streamUrl: 'http://test/short.mp4',
      positionMs: 8000,
      durationMs: 7200000,
      type: 'movie',
    );
    var history = await WatchHistoryService.loadHistory();
    expect(history.isEmpty, isTrue);

    // 2. Playback over 10 seconds is recorded
    await WatchHistoryService.saveProgress(
      id: 'vod_short',
      title: 'Short Movie',
      streamUrl: 'http://test/short.mp4',
      positionMs: 15000,
      durationMs: 7200000,
      type: 'movie',
    );
    history = await WatchHistoryService.loadHistory();
    expect(history.length, equals(1));
    expect(history.first.positionMs, equals(15000));

    // 3. Playback updated upon pause or seek to 50%
    await WatchHistoryService.saveProgress(
      id: 'vod_short',
      title: 'Short Movie',
      streamUrl: 'http://test/short.mp4',
      positionMs: 3600000,
      durationMs: 7200000,
      type: 'movie',
    );
    history = await WatchHistoryService.loadHistory();
    expect(history.length, equals(1));
    expect(history.first.positionMs, equals(3600000));

    // 4. Playback >= 93% (finished) removes it from Continue Watching
    await WatchHistoryService.saveProgress(
      id: 'vod_short',
      title: 'Short Movie',
      streamUrl: 'http://test/short.mp4',
      positionMs: 6800000, // ~94.4%
      durationMs: 7200000,
      type: 'movie',
    );
    history = await WatchHistoryService.loadHistory();
    expect(history.isEmpty, isTrue);
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String? downloadUrl;
  final String fileName;
  final bool hasUpdate;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileName,
    required this.hasUpdate,
  });
}

class UpdateService {
  static const String _repoOwner = 'satodu';
  static const String _repoName = 'panda-iptv';

  /// Compara se `remote` é estritamente maior que `current` (ex: "0.0.2" > "0.0.1", ou "0.0.1" > "0.0.1-alpha")
  static bool isNewerVersion(String current, String remote) {
    try {
      final cleanCurrentRaw = current.split('+').first.replaceFirst('v', '').trim();
      final cleanRemoteRaw = remote.split('+').first.replaceFirst('v', '').trim();

      final currentHasPre = cleanCurrentRaw.contains('-');
      final remoteHasPre = cleanRemoteRaw.contains('-');

      final cleanCurrent = cleanCurrentRaw.split('-').first;
      final cleanRemote = cleanRemoteRaw.split('-').first;

      final currentParts = cleanCurrent.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final remoteParts = cleanRemote.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      final maxLen = currentParts.length > remoteParts.length ? currentParts.length : remoteParts.length;
      for (int i = 0; i < maxLen; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final r = i < remoteParts.length ? remoteParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }

      // Se números base são idênticos (ex: 0.0.1 e 0.0.1), mas o atual é prerelease (-alpha) e o remoto é estável, remoto é mais novo
      if (currentHasPre && !remoteHasPre) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Remove APKs antigos ou corrompidos salvos no cache temporário para não ocupar espaço na TV
  static Future<void> cleanupOldApks() async {
    try {
      if (!Platform.isAndroid) return;
      final dir = await getTemporaryDirectory();
      if (!await dir.exists()) return;
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
          try {
            await entity.delete();
            debugPrint('[PANDA UPDATE] Removido APK antigo do cache: ${entity.path}');
          } catch (e) {
            debugPrint('[PANDA UPDATE] Erro ao remover APK: ${entity.path} ($e)');
          }
        }
      }
    } catch (e) {
      debugPrint('[PANDA UPDATE] Erro em cleanupOldApks: $e');
    }
  }

  /// Verifica se há atualização disponível no GitHub Releases
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Limpa resíduos de atualizações anteriores para liberar espaço no Android TV / Firestick
      await cleanupOldApks();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final url = Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest');
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'PandaIPTV-Updater',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
      final releaseNotes = data['body'] as String? ?? '';
      final assets = (data['assets'] as List<dynamic>? ?? []);

      final hasUpdate = isNewerVersion(currentVersion, tagName);
      if (!hasUpdate) return null;

      String? downloadUrl;
      String fileName = '';

      if (Platform.isAndroid) {
        // Procura o APK nos assets
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String?;
            fileName = name;
            // Prefere Panda-IPTV.apk ou o APK versionado geral
            if (name == 'Panda-IPTV.apk' || name.contains(tagName)) break;
          }
        }
      } else if (Platform.isLinux) {
        // Procura o AppImage nos assets
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.AppImage')) {
            downloadUrl = asset['browser_download_url'] as String?;
            fileName = name;
            break;
          }
        }
      }

      return UpdateInfo(
        latestVersion: tagName,
        currentVersion: currentVersion,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        fileName: fileName,
        hasUpdate: true,
      );
    } catch (e) {
      debugPrint('[PANDA UPDATE CHECK ERROR] $e');
      return null;
    }
  }

  /// Baixa o instalador com notificação de progresso (0.0 a 1.0) e dispara a instalação
  static Future<void> downloadAndInstall({
    required UpdateInfo updateInfo,
    required Function(double progress) onProgress,
    required Function(String error) onError,
    required Function() onReadyToInstall,
  }) async {
    final downloadUrl = updateInfo.downloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      onError('URL de download não encontrada.');
      return;
    }

    try {
      if (Platform.isAndroid) {
        // Garante que APKs antigos sejam excluídos antes de baixar o novo
        await cleanupOldApks();

        // 1. Baixa o arquivo para a pasta de cache do app
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/${updateInfo.fileName.isNotEmpty ? updateInfo.fileName : 'Panda-IPTV-update.apk'}';
        final file = File(filePath);

        final client = http.Client();
        final request = http.Request('GET', Uri.parse(downloadUrl));
        final response = await client.send(request);

        if (response.statusCode != 200) {
          onError('Falha ao baixar atualização (HTTP ${response.statusCode})');
          return;
        }

        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final sink = file.openWrite();

        await response.stream.listen((chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            onProgress(receivedBytes / totalBytes);
          }
        }).asFuture();

        await sink.close();
        client.close();

        onReadyToInstall();

        // 2. Invoca o instalador nativo do sistema Android
        final openResult = await OpenFilex.open(
          filePath,
          type: 'application/vnd.android.package-archive',
        );

        if (openResult.type != ResultType.done) {
          // Fallback: abre no navegador caso a intent direta seja restringida
          final uri = Uri.parse(downloadUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            onError('Erro ao abrir instalador: ${openResult.message}');
          }
        }
      } else if (Platform.isLinux) {
        // No Linux Desktop: abre a URL direta para salvar/executar o AppImage
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          onReadyToInstall();
        } else {
          onError('Não foi possível abrir o navegador.');
        }
      }
    } catch (e) {
      debugPrint('[PANDA UPDATE DOWNLOAD ERROR] $e');
      onError('Erro durante o download: $e');
    }
  }
}

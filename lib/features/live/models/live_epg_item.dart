import 'dart:convert';

/// Item da programação EPG (Guia de Programação Eletrônico)
class LiveEpgItem {
  final String id;
  final String epgId;
  final String title;
  final String? description;
  final DateTime? start;
  final DateTime? end;
  final int startTimestamp;
  final int stopTimestamp;

  const LiveEpgItem({
    required this.id,
    required this.epgId,
    required this.title,
    this.description,
    this.start,
    this.end,
    this.startTimestamp = 0,
    this.stopTimestamp = 0,
  });

  /// Decodifica com segurança caso venha codificado em Base64 pelo servidor Xtream Codes
  static String _decodeBase64IfNeeded(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString().trim();
    if (str.isEmpty) return '';

    // Verifica se é uma string base64 válida
    try {
      if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(str) && str.length % 4 == 0) {
        final bytes = base64Decode(str);
        final decoded = utf8.decode(bytes, allowMalformed: true);
        if (decoded.trim().isNotEmpty) return decoded.trim();
      }
    } catch (_) {}

    return str;
  }

  factory LiveEpgItem.fromJson(Map<String, dynamic> json) {
    final rawStart = json['start']?.toString();
    final rawEnd = json['end']?.toString();

    DateTime? parsedStart;
    DateTime? parsedEnd;

    if (rawStart != null && rawStart.isNotEmpty) {
      parsedStart = DateTime.tryParse(rawStart) ??
          DateTime.tryParse(rawStart.replaceAll(' ', 'T'));
    }

    if (rawEnd != null && rawEnd.isNotEmpty) {
      parsedEnd = DateTime.tryParse(rawEnd) ??
          DateTime.tryParse(rawEnd.replaceAll(' ', 'T'));
    }

    final startTs = int.tryParse(json['start_timestamp']?.toString() ?? '') ??
        (parsedStart != null ? parsedStart.millisecondsSinceEpoch ~/ 1000 : 0);

    final stopTs = int.tryParse(json['stop_timestamp']?.toString() ?? '') ??
        (parsedEnd != null ? parsedEnd.millisecondsSinceEpoch ~/ 1000 : 0);

    return LiveEpgItem(
      id: json['id']?.toString() ?? '',
      epgId: json['epg_id']?.toString() ?? '',
      title: _decodeBase64IfNeeded(json['title']),
      description: _decodeBase64IfNeeded(json['description']),
      start: parsedStart,
      end: parsedEnd,
      startTimestamp: startTs,
      stopTimestamp: stopTs,
    );
  }

  /// Retorna se o programa está no ar neste exato momento
  bool get isNow {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (startTimestamp > 0 && stopTimestamp > 0) {
      return now >= startTimestamp && now <= stopTimestamp;
    }
    if (start != null && end != null) {
      final nowDt = DateTime.now();
      return nowDt.isAfter(start!) && nowDt.isBefore(end!);
    }
    return false;
  }

  /// Progresso do programa atual de 0.0 a 1.0
  double get progress {
    if (!isNow || stopTimestamp <= startTimestamp) return 0.0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final total = stopTimestamp - startTimestamp;
    final elapsed = now - startTimestamp;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Minutos restantes até o fim do programa
  int get remainingMinutes {
    if (!isNow || stopTimestamp <= 0) return 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remainingSeconds = stopTimestamp - now;
    return (remainingSeconds / 60).clamp(0, 9999).toInt();
  }

  /// Formatação limpa de horário: ex "14:00 - 15:30"
  String get timeFormatted {
    String formatTime(DateTime? dt, int ts) {
      if (dt != null) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      if (ts > 0) {
        final dtTs = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        final h = dtTs.hour.toString().padLeft(2, '0');
        final m = dtTs.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      return '';
    }

    final startStr = formatTime(start, startTimestamp);
    final endStr = formatTime(end, stopTimestamp);

    if (startStr.isNotEmpty && endStr.isNotEmpty) {
      return '$startStr - $endStr';
    } else if (startStr.isNotEmpty) {
      return startStr;
    }
    return '';
  }
}

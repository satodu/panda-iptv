import 'package:http/http.dart' as http;

/// Cliente HTTP personalizado que injeta cabeçalhos universais de IPTV
/// (User-Agent e Accept) para garantir compatibilidade com proxies, WAFs,
/// Cloudflare e servidores Xtream Codes / XUI.one em todas as plataformas
/// (Windows, Linux, Android).
class XtreamHttpClient extends http.BaseClient {
  final http.Client _inner;

  static const String userAgent = 'IPTVSmartersPro/3.1.5 (Linux; Android 12)';

  static const Map<String, String> defaultHeaders = {
    'User-Agent': userAgent,
    'Accept': '*/*',
    'Connection': 'keep-alive',
  };

  XtreamHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    defaultHeaders.forEach((key, value) {
      if (!request.headers.containsKey(key)) {
        request.headers[key] = value;
      }
    });
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

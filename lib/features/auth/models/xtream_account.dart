/// Modelos de dados para autenticação Xtream Codes
class XtreamUserInfo {
  final String username;
  final String status;
  final String expDate;
  final bool isTrial;
  final String activeCons;
  final String maxConnections;

  XtreamUserInfo({
    required this.username,
    required this.status,
    required this.expDate,
    required this.isTrial,
    required this.activeCons,
    required this.maxConnections,
  });

  factory XtreamUserInfo.fromJson(Map<String, dynamic> json) {
    return XtreamUserInfo(
      username: json['username']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      expDate: json['exp_date']?.toString() ?? '',
      isTrial: json['is_trial'] == '1' || json['is_trial'] == true,
      activeCons: json['active_cons']?.toString() ?? '0',
      maxConnections: json['max_connections']?.toString() ?? '1',
    );
  }
}

class XtreamServerInfo {
  final String url;
  final String port;
  final String httpsPort;
  final String serverProtocol;
  final String timezone;

  XtreamServerInfo({
    required this.url,
    required this.port,
    required this.httpsPort,
    required this.serverProtocol,
    required this.timezone,
  });

  factory XtreamServerInfo.fromJson(Map<String, dynamic> json) {
    return XtreamServerInfo(
      url: json['url']?.toString() ?? '',
      port: json['port']?.toString() ?? '80',
      httpsPort: json['https_port']?.toString() ?? '443',
      serverProtocol: json['server_protocol']?.toString() ?? 'http',
      timezone: json['timezone']?.toString() ?? 'UTC',
    );
  }
}

class XtreamAccount {
  final String serverUrl;
  final String username;
  final String password;
  final XtreamUserInfo userInfo;
  final XtreamServerInfo serverInfo;

  XtreamAccount({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.userInfo,
    required this.serverInfo,
  });
}

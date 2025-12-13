import 'dart:convert';

import 'package:http/http.dart' as http;

class RemoteLogger {
  const RemoteLogger._();

  static const String _endpoint =
      'http://127.0.0.1:7242/ingest/02d6f98d-c83f-4008-a173-897933848c97';

  static void log({
    required String hypothesisId,
    required String location,
    required String message,
    Map<String, dynamic>? data,
    String runId = 'pre-fix',
  }) {
    // #region agent log
    () async {
      try {
        await http.post(
          Uri.parse(_endpoint),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sessionId': 'debug-session',
            'runId': runId,
            'hypothesisId': hypothesisId,
            'location': location,
            'message': message,
            'data': data ?? const <String, dynamic>{},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }),
        );
      } catch (_) {
        // Ignore: debug only.
      }
    }();
    // #endregion
  }
}



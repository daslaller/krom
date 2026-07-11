import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LiveShareService extends ChangeNotifier {
  WebSocketChannel? _channel;
  String? _sessionId;
  final _incoming = StreamController<LiveShareEdit>.broadcast();

  bool get isConnected => _channel != null;
  String? get sessionId => _sessionId;
  Stream<LiveShareEdit> get incomingEdits => _incoming.stream;

  Future<void> join({
    required String relayUrl,
    required String sessionId,
    required String participantId,
  }) async {
    await leave();
    _sessionId = sessionId;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(relayUrl));
      _channel!.stream.listen(
        _onMessage,
        onError: (_) => leave(),
        onDone: leave,
      );
      _send({
        'type': 'join',
        'sessionId': sessionId,
        'participantId': participantId,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('LiveShare join failed: $e');
      await leave();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      if (msg['type'] == 'edit') {
        _incoming.add(LiveShareEdit(
          participantId: msg['participantId'] as String? ?? '',
          filePath: msg['filePath'] as String? ?? '',
          rangeStart: msg['rangeStart'] as int? ?? 0,
          rangeEnd: msg['rangeEnd'] as int? ?? 0,
          text: msg['text'] as String? ?? '',
        ));
      }
    } catch (_) {}
  }

  void broadcastEdit({
    required String filePath,
    required int rangeStart,
    required int rangeEnd,
    required String text,
    required String participantId,
  }) {
    if (_channel == null) return;
    _send({
      'type': 'edit',
      'sessionId': _sessionId,
      'participantId': participantId,
      'filePath': filePath,
      'rangeStart': rangeStart,
      'rangeEnd': rangeEnd,
      'text': text,
    });
  }

  void _send(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  Future<void> leave() async {
    if (_channel != null) {
      try {
        _send({'type': 'leave', 'sessionId': _sessionId});
      } catch (_) {}
      await _channel!.sink.close();
    }
    _channel = null;
    _sessionId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(leave());
    _incoming.close();
    super.dispose();
  }
}

class LiveShareEdit {
  const LiveShareEdit({
    required this.participantId,
    required this.filePath,
    required this.rangeStart,
    required this.rangeEnd,
    required this.text,
  });

  final String participantId;
  final String filePath;
  final int rangeStart;
  final int rangeEnd;
  final String text;
}

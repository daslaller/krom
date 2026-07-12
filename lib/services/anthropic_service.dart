import 'dart:convert';

import 'package:http/http.dart' as http;

import 'settings_service.dart';

class AnthropicService {
  AnthropicService(this.settings);

  final SettingsService settings;

  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-3-5-haiku-20241022';

  bool get isConfigured => settings.hasAnthropicKey;

  Future<String> chat({
    required String system,
    required String userMessage,
    int maxTokens = 1024,
  }) async {
    final key = settings.anthropicApiKey;
    if (key == null || key.isEmpty) {
      throw StateError('Anthropic API key not configured');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': maxTokens,
        'system': system,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Anthropic API error ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) return '';
    final first = content.first as Map<String, dynamic>;
    return first['text'] as String? ?? '';
  }

  Future<String?> completeLine({
    required String prefix,
    required String languageId,
  }) async {
    if (!isConfigured) return null;
    try {
      final result = await chat(
        system:
            'Reply with ONLY text appended after cursor. Language: $languageId.',
        userMessage: 'Complete after cursor:\n$prefix',
        maxTokens: 64,
      );
      final trimmed = result.trim();
      if (trimmed.isEmpty || trimmed.contains('\n')) return null;
      return trimmed;
    } catch (_) {
      return null;
    }
  }
}

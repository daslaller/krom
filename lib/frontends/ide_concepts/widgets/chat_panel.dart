import 'package:flutter/material.dart';

import '../../../editor/editor_session.dart';
import '../../../services/anthropic_service.dart';
import '../../../services/chat_context_builder.dart';
import '../../../services/settings_service.dart';
import '../ide_fonts.dart';
import '../ide_concepts_theme.dart';

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});
  final String role;
  final String text;
}

class IdeConceptsChatPanel extends StatefulWidget {
  const IdeConceptsChatPanel({
    super.key,
    required this.theme,
    required this.session,
    required this.settings,
    required this.onClose,
  });

  final IdeConceptsTheme theme;
  final EditorSession session;
  final SettingsService settings;
  final VoidCallback onClose;

  @override
  State<IdeConceptsChatPanel> createState() => _IdeConceptsChatPanelState();
}

class _IdeConceptsChatPanelState extends State<IdeConceptsChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _busy = false;
  late final AnthropicService _anthropic;

  @override
  void initState() {
    super.initState();
    _anthropic = AnthropicService(widget.settings);
    if (!_anthropic.isConfigured) {
      _messages.add(const _ChatMessage(
        role: 'system',
        text:
            'Offline mode — add "anthropicApiKey" to ~/.config/krom/settings.json.',
      ));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;

    final editorContext = ChatContextBuilder.build(widget.session);
    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _busy = true;
      _input.clear();
    });

    if (!_anthropic.isConfigured) {
      setState(() {
        _messages.add(const _ChatMessage(
          role: 'assistant',
          text: '(Stub) Configure anthropicApiKey for real answers.',
        ));
        _busy = false;
      });
      return;
    }

    try {
      final reply = await _anthropic.chat(
        system: 'You are Krom, a concise coding assistant.',
        userMessage:
            'Editor context:\n$editorContext\n\nUser question:\n$text',
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', text: reply));
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', text: 'Error: $e'));
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Container(
      color: theme.sidebarBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chat',
                    style: IdeFonts.mono(
                      color: theme.text,
                      fontSize: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: theme.iconDim),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.hairline),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    m.text,
                    style: IdeFonts.mono(
                      fontSize: 12.5,
                      height: 1.45,
                      color: m.role == 'user' ? theme.text : theme.muted,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_busy) LinearProgressIndicator(minHeight: 2, color: theme.accent),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    style: IdeFonts.mono(fontSize: 12.5, color: theme.text),
                    decoration: InputDecoration(
                      hintText: 'Ask about this file…',
                      hintStyle:
                          IdeFonts.mono(color: theme.iconDim, fontSize: 12),
                      filled: true,
                      fillColor: theme.editorBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: theme.hairline),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: theme.accent, size: 20),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

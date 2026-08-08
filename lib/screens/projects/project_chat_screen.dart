import 'package:flutter/material.dart';

import '../../models/business.dart';
import '../../models/work.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/formatted_text.dart';

/// A focused AI chat scoped to a single project.
class ProjectChatScreen extends StatefulWidget {
  final Project project;
  final Map<String, dynamic> context;
  const ProjectChatScreen(
      {super.key, required this.project, required this.context});

  @override
  State<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends State<ProjectChatScreen> {
  final _ai = AiService();
  final _controller = TextEditingController();
  final _messages = <ChatMessage>[];
  bool _thinking = false;

  static const _suggestions = [
    'What is blocking this project?',
    'Are we on track?',
    'What should happen next?',
    'What are the biggest risks?',
  ];

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final history = List<ChatMessage>.from(_messages);
    setState(() {
      _messages.add(ChatMessage(text: t, fromUser: true));
      _thinking = true;
      _controller.clear();
    });
    String reply;
    try {
      final r = await _ai.chat(
          message: t, history: history, project: widget.context);
      reply = r.text;
    } catch (_) {
      reply =
          'AI is unavailable right now. Deploy the ai function or try again.';
    }
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: reply, fromUser: false));
      _thinking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Project AI', style: TextStyle(fontSize: 16)),
            Text(widget.project.name,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                for (final m in _messages) _bubble(context, m),
                if (_thinking)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Thinking…'),
                    ]),
                  ),
                if (_messages.isEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions
                        .map((s) => ActionChip(
                            label: Text(s), onPressed: () => _send(s)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                          hintText: 'Ask about this project…'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton.small(
                    elevation: 0,
                    onPressed: () => _send(_controller.text),
                    child: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, ChatMessage m) {
    final isUser = m.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? AppColors.brand : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border:
              isUser ? null : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: isUser
            ? Text(m.text,
                style: const TextStyle(height: 1.4, color: Colors.white))
            : FormattedText(m.text),
      ),
    );
  }
}

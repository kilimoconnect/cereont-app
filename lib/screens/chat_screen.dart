import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/work.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/formatted_text.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  static const _suggestions = [
    'What should I focus on today?',
    'Which customers need follow-up?',
    'Who are my most reliable suppliers?',
    'What risks should I worry about?',
    'Summarize my business performance.',
  ];

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final state = context.read<AppState>();
    _controller.clear();
    _scrollDown();
    await state.sendChat(t);
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final chat = state.chat;
    final thinking = state.aiThinking;

    return Scaffold(
      // Composer handles the keyboard inset manually (see _composer) so the
      // input always sits directly above the keyboard.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.brand, AppColors.accent]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Chief of Staff',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Business-aware assistant',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.isEmpty && !thinking
                ? _welcome(context)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: chat.length + (thinking ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= chat.length) return const _TypingBubble();
                      return _Bubble(message: chat[i]);
                    },
                  ),
          ),
          if (chat.isEmpty)
            _suggestionStrip()
          else
            const SizedBox.shrink(),
          _composer(context),
        ],
      ),
    );
  }

  Widget _welcome(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.accent]),
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 16),
        Text('Ask me anything about your business',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'I remember your customers, suppliers, tasks and inbox — '
          'and I can help you decide what matters most.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _suggestionStrip() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(_suggestions[i]),
          onPressed: () => _send(_suggestions[i]),
        ),
      ),
    );
  }

  Widget _composer(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    hintText: 'Message your chief of staff…',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FloatingActionButton.small(
                onPressed: () => _send(_controller.text),
                elevation: 0,
                child: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.brand
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: isUser
            ? Text(
                message.text,
                style: const TextStyle(height: 1.4, color: Colors.white),
              )
            : FormattedText(message.text),
      ),
    );
  }
}

/// Animated "…" bubble shown while the assistant is composing a reply.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_c.value - i * 0.2) % 1.0;
                final opacity = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  child: Opacity(
                    opacity: opacity.clamp(0.3, 1.0),
                    child: const CircleAvatar(
                        radius: 3.5, backgroundColor: AppColors.brand),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

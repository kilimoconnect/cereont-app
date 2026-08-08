import 'package:flutter/material.dart';

/// Lightweight, dependency-free Markdown renderer for AI-generated text.
///
/// Handles the subset models actually emit: headings (`#`..`###`), bullet
/// lists (`-`, `*`, `•`), numbered lists (`1.`), blank-line paragraph breaks,
/// and inline `**bold**`, `*italic*` / `_italic_`, and `` `code` ``. Anything
/// it doesn't recognise is rendered as plain text, so it can never show raw
/// `**` markers to the user.
class FormattedText extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;
  final double height;

  const FormattedText(
    this.text, {
    super.key,
    this.color,
    this.fontSize = 14.5,
    this.height = 1.42,
  });

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.copyWith(
          color: color,
          fontSize: fontSize,
          height: height,
        );

    final blocks = <Widget>[];
    final lines = text.replaceAll('\r\n', '\n').split('\n');

    for (var raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) {
        // Blank line => small vertical gap between paragraphs.
        blocks.add(const SizedBox(height: 8));
        continue;
      }

      // Headings: #, ##, ###
      final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
      if (heading != null) {
        final level = heading.group(1)!.length;
        final content = heading.group(2)!;
        final size = level == 1
            ? fontSize + 5
            : level == 2
                ? fontSize + 3
                : fontSize + 1;
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: RichText(
            text: _inline(
                content, base.copyWith(fontSize: size, fontWeight: FontWeight.w700)),
          ),
        ));
        continue;
      }

      // Bullet list: -, *, •
      final bullet = RegExp(r'^[-*•]\s+(.*)$').firstMatch(trimmed);
      if (bullet != null) {
        blocks.add(_listItem(context, base, '•  ', bullet.group(1)!));
        continue;
      }

      // Numbered list: 1. 2. ...
      final numbered = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numbered != null) {
        blocks.add(
            _listItem(context, base, '${numbered.group(1)}.  ', numbered.group(2)!));
        continue;
      }

      // Plain paragraph line.
      blocks.add(RichText(text: _inline(line, base)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  Widget _listItem(
      BuildContext context, TextStyle base, String marker, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(marker, style: base),
          Expanded(child: RichText(text: _inline(content, base))),
        ],
      ),
    );
  }

  /// Parse inline markers (**bold**, *italic*, _italic_, `code`) into spans.
  TextSpan _inline(String input, TextStyle base) {
    final spans = <TextSpan>[];
    // Matches **bold**, *italic*, _italic_, or `code`.
    final pattern = RegExp(
        r'\*\*(.+?)\*\*|\*(.+?)\*|_(.+?)_|`(.+?)`');
    var index = 0;
    for (final m in pattern.allMatches(input)) {
      if (m.start > index) {
        spans.add(TextSpan(text: input.substring(index, m.start), style: base));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(
            text: m.group(1),
            style: base.copyWith(fontWeight: FontWeight.w700)));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(
            text: m.group(2),
            style: base.copyWith(fontStyle: FontStyle.italic)));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(
            text: m.group(3),
            style: base.copyWith(fontStyle: FontStyle.italic)));
      } else if (m.group(4) != null) {
        spans.add(TextSpan(
            text: m.group(4),
            style: base.copyWith(
              fontFamily: 'monospace',
              fontFeatures: const [],
              backgroundColor: base.color?.withValues(alpha: 0.10),
            )));
      }
      index = m.end;
    }
    if (index < input.length) {
      spans.add(TextSpan(text: input.substring(index), style: base));
    }
    return TextSpan(style: base, children: spans);
  }
}

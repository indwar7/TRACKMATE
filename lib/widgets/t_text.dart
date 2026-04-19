// lib/widgets/t_text.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/language_controller.dart';

class TText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool smartBreak; // if true, inserts newline for long translations near middle

  const TText(
      this.text, {
        super.key,
        this.style,
        this.textAlign,
        this.maxLines,
        this.smartBreak = false,
      });

  String _insertSmartBreak(String t) {
    // If it's multi-line already, keep it
    if (t.contains('\n')) return t;
    // If short, return
    if (t.length <= 18) return t;
    // Try to split near middle at a space
    final mid = t.length ~/ 2;
    final leftSpace = t.lastIndexOf(' ', mid);
    final rightSpace = t.indexOf(' ', mid);
    int split = leftSpace != -1 ? leftSpace : rightSpace != -1 ? rightSpace : -1;
    if (split == -1) return t; // can't split
    final before = t.substring(0, split).trim();
    final after = t.substring(split + 1).trim();
    return '$before\n$after';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(builder: (lc) {
      // Each rebuild (when lc.update() is called) will trigger FutureBuilder again
      return FutureBuilder<String>(
        future: lc.translate(text),
        builder: (context, snap) {
          String toShow = snap.data ?? text;
          if (smartBreak && toShow.trim().isNotEmpty) {
            toShow = _insertSmartBreak(toShow);
          }
          if (snap.connectionState == ConnectionState.waiting) {
            // show original slightly faded while translating
            return Text(
              text,
              style: style?.copyWith(color: style?.color?.withValues(alpha: 0.6) ?? Colors.white70),
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            );
          }
          return Text(
            toShow,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          );
        },
      );
    });
  }
}
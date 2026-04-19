import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/language_controller.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const TranslatedText(
      this.text, {
        Key? key,
        this.style,
        this.textAlign,
      }) : super(key: key);

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  late Future<String> translatedText;
  final languageController = Get.find<LanguageController>();

  get TranslationService => null;

  @override
  void initState() {
    super.initState();
    translatedText = _getTranslation();
  }

  @override
  void didUpdateWidget(covariant TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If language changes → refresh translation
    if (oldWidget.text != widget.text ||
        oldWidget.textAlign != widget.textAlign) {
      translatedText = _getTranslation();
      setState(() {});
    }
  }

  Future<String> _getTranslation() async {
    final target = languageController.currentLang.value;
    debugPrint('🔄 Getting translation for: "${widget.text}" to $target');

    // No need to translate English → English
    if (target == 'en') {
      debugPrint('ℹ️ No translation needed (already in English)');
      return widget.text;
    }

    try {
      final translated = await TranslationService.translateText(
        text: widget.text,
        targetLanguage: target,
        sourceLanguage: 'en',
      );
      debugPrint('✅ Translated "${widget.text}" to: "$translated"');
      return translated;
    } catch (e) {
      debugPrint('❌ Translation error: $e');
      return widget.text; // Return original text on error
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-translate when language changes
    translatedText = _getTranslation();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // This will make the widget rebuild when language changes
      final currentLang = languageController.currentLang.value;

      return FutureBuilder<String>(
        future: _getTranslation(),
        builder: (context, snapshot) {
          final text = snapshot.data ?? widget.text;
          return Text(
            text,
            style: widget.style,
            textAlign: widget.textAlign,
          );
        },
      );
    });
  }
}
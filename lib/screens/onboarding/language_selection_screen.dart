import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trackmate_app/controllers/language_controller.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  _LanguageSelectionScreenState createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late final LanguageController _languageController;
  late String _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    _languageController = Get.find<LanguageController>();
    _selectedLanguageCode = _languageController.currentLang.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16213E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Select Language',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search language',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF0F0F1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _languageController.supportedLanguages.length,
              itemBuilder: (context, index) {
                final lang = _languageController.supportedLanguages[index];
                return ListTile(
                  title: Text(
                    lang.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: _selectedLanguageCode == lang.code
                      ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLanguageCode = lang.code;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _languageController.changeLanguage(_selectedLanguageCode);
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
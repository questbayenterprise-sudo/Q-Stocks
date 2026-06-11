import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});
  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selected = "English";
  @override
  Widget build(BuildContext context) {
    final langs = ["English", "Hindi", "Arabic", "Spanish", "French"];
    return Scaffold(
      appBar: AppBar(title: const Text("Language")),
      body: ListView(
        children: langs
            .map(
              (l) => RadioListTile(
                title: Text(l),
                value: l,
                groupValue: _selected,
                activeColor: const Color(0xFF00A36C),
                onChanged: (v) => setState(() => _selected = v!),
              ),
            )
            .toList(),
      ),
    );
  }
}

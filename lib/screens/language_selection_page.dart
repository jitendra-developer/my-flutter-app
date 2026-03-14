import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../chat_provider.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi (हिंदी)'},
    {'code': 'mr', 'name': 'Marathi (मराठी)'},
    {'code': 'gu', 'name': 'Gujarati (ગુજરાતી)'},
    {'code': 'ta', 'name': 'Tamil (தமிழ்)'},
    {'code': 'te', 'name': 'Telugu (తెలుగు)'},
    {'code': 'bn', 'name': 'Bengali (বাংলা)'},
    {'code': 'kn', 'name': 'Kannada (ಕನ್ನಡ)'},
    {'code': 'ml', 'name': 'Malayalam (മലയാളം)'},
    {'code': 'pa', 'name': 'Punjabi (ਪੰਜਾਬੀ)'},
  ];

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentLanguage = chatProvider.appLanguage;

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          chatProvider.l10n.translate('language'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        itemCount: _languages.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = lang['code'] == chatProvider.appLanguage;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: isSelected ? const Color(0xFF1C1C24) : Colors.transparent,
            title: Text(
              lang['name']!,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Color(0xFF4A60D4))
                : null,
            onTap: () {
              chatProvider.setAppLanguage(lang['code']!);
              context.pop();
              
              String feedback = 'Language set to ${lang['name']}';
              switch (lang['code']) {
                case 'hi': feedback = 'भाषा ${lang['name']} पर सेट की गई'; break;
                case 'mr': feedback = 'भाषा ${lang['name']} वर सेट केली'; break;
                case 'gu': feedback = 'ભાષા ${lang['name']} પર સેટ છે'; break;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(feedback),
                  backgroundColor: const Color(0xFF4A60D4),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

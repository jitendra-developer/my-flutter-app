import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/chat_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          Provider.of<ChatProvider>(context).l10n.translate('settings'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: chatProvider.l10n.translate('language'),
            subtitle: _getSubtitleForLanguage(chatProvider.appLanguage),
            onTap: () {
              context.push('/language-selection');
            },
          ),
          const Divider(color: Colors.white10, height: 32),
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: chatProvider.l10n.translate('profile'),
            subtitle: _getSubtitleForProfile(chatProvider.appLanguage),
            onTap: () {
              // Future features
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(chatProvider.l10n.translate('profile') + ' coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getSubtitleForLanguage(String lang) {
    switch (lang) {
      case 'Hindi': return 'ऐप की भाषा बदलें';
      case 'Marathi': return 'अॅपची भाषा बदला';
      case 'Gujarati': return 'એપ્લિકેશનની ભાષા બદલો';
      case 'Tamil': return 'பயன்பாட்டு மொழியை மாற்றவும்';
      case 'Telugu': return 'యాప్ భాషను మార్చండి';
      case 'Bengali': return 'অ্যাপের ভাষা পরিবর্তন করুন';
      case 'Kannada': return 'ಅಪ್ಲಿಕೇಶನ್ ಭಾಷೆಯನ್ನು ಬದಲಾಯಿಸಿ';
      case 'Malayalam': return 'ആപ്പ് ഭാഷ മാറ്റുക';
      case 'Punjabi': return 'ਐਪ ਦੀ ਭਾਸ਼ਾ ਬਦਲੋ';
      default: return 'Change the app language';
    }
  }

  String _getSubtitleForProfile(String lang) {
    switch (lang) {
      case 'Hindi': return 'अपना विवरण अपडेट करें';
      case 'Marathi': return 'आपले तपशील अपडेट करा';
      case 'Gujarati': return 'તમારી વિગતો અપડેટ કરો';
      case 'Tamil': return 'உங்கள் விவரங்களைப் புதுப்பிக்கவும்';
      case 'Telugu': return 'మీ వివరాలను అప్‌డేట్ చేయండి';
      case 'Bengali': return 'আপনার বিবরণ আপডেট করুন';
      case 'Kannada': return 'ನಿಮ್ಮ ವಿವರಗಳನ್ನು ನವೀಕರಿಸಿ';
      case 'Malayalam': return 'നിങ്ങളുടെ വിശദാംശങ്ങൾ അപ്‌ഡേറ്റ് ചെയ്യുക';
      case 'Punjabi': return 'ਆਪਣੇ ਵੇਰਵਿਆਂ ਨੂੰ ਅਪਡੇਟ ਕਰੋ';
      default: return 'Update your details';
    }
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C24),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white54,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      onTap: onTap,
    );
  }
}

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
        ],
      ),
    );
  }

  String _getSubtitleForLanguage(String lang) {
    switch (lang) {
      case 'hi': return '\u0910\u092a \u0915\u0940 \u092d\u093e\u0937\u093e \u092c\u0926\u0932\u0947\u0902';
      case 'mr': return '\u0905\u0945\u092a\u091a\u0940 \u092d\u093e\u0937\u093e \u092c\u0926\u0932\u093e';
      case 'gu': return '\u0a8f\u0aaa\u0acd\u0ab2\u0abf\u0a95\u0ac7\u0ab6\u0aa8\u0aa8\u0ac0 \u0aad\u0abe\u0ab7\u0abe \u0aac\u0aa6\u0ab2\u0acb';
      case 'ta': return '\u0baa\u0baf\u0ba9\u0bcd\u0baa\u0bbe\u0b9f\u0bcd\u0b9f\u0bc1 \u0bae\u0bca\u0bb4\u0bbf\u0baf\u0bc8 \u0bae\u0bbe\u0bb1\u0bcd\u0bb1\u0bb5\u0bc1\u0bae\u0bcd';
      case 'te': return '\u0c2f\u0c3e\u0c2a\u0c4d \u0c2d\u0c3e\u0c37\u0c28\u0c41 \u0c2e\u0c3e\u0c30\u0c4d\u0c1a\u0c02\u0c21\u0c3f';
      case 'bn': return '\u0985\u09cd\u09af\u09be\u09aa\u09c7\u09b0 \u09ad\u09be\u09b7\u09be \u09aa\u09b0\u09bf\u09ac\u09b0\u09cd\u09a4\u09a8 \u0995\u09b0\u09c1\u09a8';
      case 'kn': return '\u0c85\u0caa\u0ccd\u0cb2\u0cbf\u0c95\u0cc7\u0cb6\u0ca8\u0ccd \u0cad\u0cbe\u0cb7\u0cc6\u0caf\u0ca8\u0ccd\u0ca8\u0cc1 \u0cac\u0ca6\u0cb2\u0cbe\u0caf\u0cbf\u0cb8\u0cbf';
      case 'ml': return '\u0d06\u0d2a\u0d4d\u0d2a\u0d4d \u0d2d\u0d3e\u0d37 \u0d2e\u0d3e\u0d31\u0d4d\u0d31\u0d41\u0d15';
      case 'pa': return '\u0a10\u0a2a \u0a26\u0a40 \u0a2d\u0a3e\u0a38\u0a3c\u0a3e \u0a2c\u0a26\u0a32\u0a4b';
      default: return 'Change the app language';
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

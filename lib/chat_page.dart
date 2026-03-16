
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:myapp/services/api_service.dart';
import 'package:myapp/screens/profile_page.dart';
import 'chat_provider.dart';
import 'history_page.dart';
import 'screens/pre_prompts_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _apiService = ApiService();
  String _userName = 'User Name';
  String _userInitials = 'U';
  String? _userAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void deactivate() {
    // Stop voice mode immediately whenever the user navigates away from chat
    final cp = Provider.of<ChatProvider>(context, listen: false);
    if (cp.isContinuousVoiceMode) {
      cp.setContinuousVoiceMode(false);
      ChatInputField.globalKey.currentState?.stopListening();
    }
    super.deactivate();
  }

  Future<void> _loadUserProfile() async {
    // 1. Show cached data instantly (no flicker)
    final cached = await loadProfileCache();
    final cachedName = cached['name'] ?? '';
    if (mounted && cachedName.isNotEmpty) {
      setState(() {
        _userName = cachedName.trim().split(' ').first;
        _userInitials = profileInitials(cachedName);
        _userAvatarUrl = cached['avatarUrl'];
      });
    }

    // 2. Refresh from API silently in the background
    try {
      if (await _apiService.hasToken()) {
        final profile = await _apiService.getProfile();
        final String name = profile['name']?.toString() ?? cachedName;
        final String email = profile['email']?.toString() ?? '';
        final String? avatarUrl = profile['avatar']?.toString() ??
            profile['profile_photo_url']?.toString();
        if (name.isNotEmpty) {
          await saveProfileCache(name, email, avatarUrl);
        }
        if (mounted) {
          setState(() {
            _userName = name.trim().split(' ').first.isNotEmpty
                ? name.trim().split(' ').first
                : 'User';
            _userInitials = profileInitials(name);
            _userAvatarUrl = avatarUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing user profile: $e');
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final recentChats = chatProvider.chatHistory.take(2).toList();
    
    return Drawer(
      backgroundColor: const Color(0xFF1C1C24),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.white),
              title: Text(chatProvider.l10n.translate('new_chat'), style: const TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                final cp = Provider.of<ChatProvider>(context, listen: false);
                cp.setContinuousVoiceMode(false);
                ChatInputField.globalKey.currentState?.stopListening();
                cp.createNewChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.white),
              title: Text(chatProvider.l10n.translate('pre_prompts'), style: const TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrePromptsPage()),
                );
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: Text(chatProvider.l10n.translate('recent_chats'), style: const TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),
            if (recentChats.isNotEmpty) ...[
              ...recentChats.map((chat) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 48.0),
                  title: Text(
                    chat.title,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<ChatProvider>(context, listen: false).switchChat(chat.localId);
                  },
                );
              }),
            ],
            const Spacer(),
            const Divider(color: Colors.white24),
            ListTile(
              leading: ProfileAvatar(
                name: _userInitials,
                avatarUrl: _userAvatarUrl,
                radius: 16,
                fontSize: 13,
              ),
              title: Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile').then((_) => _loadUserProfile());
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: Text(chatProvider.l10n.translate('settings'), style: const TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(chatProvider.l10n.translate('logout'), style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                final l10n = chatProvider.l10n;
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFF2C2C2C),
                      title: Text(l10n.translate('logout'), style: const TextStyle(color: Colors.white)),
                      content: Text(l10n.translate('confirm_logout'), style: const TextStyle(color: Colors.white70)),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(l10n.translate('cancel'), style: const TextStyle(color: Colors.white70)),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final cp = Provider.of<ChatProvider>(context, listen: false);
                            // Remove token immediately so cold restart shows welcome screen
                            await _apiService.removeToken();
                            cp.clearOnLogout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                            // Fire-and-forget the server-side logout
                            _apiService.logout().catchError((_) {});
                          },
                          child: Text(l10n.translate('yes'), style: const TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(
          'Vakya Pro',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.messages.isEmpty) {
                  return const _EmptyChatState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    final isLast = index == provider.messages.length - 1;
                    return MessageBubble(message: message, isLast: isLast);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                return Offstage(
                  // Keep input bar hidden only when no messages AND not in voice mode.
                  // When voice mode starts from the welcome screen, show the input bar
                  // so the stop button is always reachable.
                  offstage: provider.messages.isEmpty && !provider.isContinuousVoiceMode,
                  child: ChatInputField(key: ChatInputField.globalKey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class _EmptyChatState extends StatefulWidget {
  const _EmptyChatState({super.key});
  @override
  _EmptyChatStateState createState() => _EmptyChatStateState();
}

class _EmptyChatStateState extends State<_EmptyChatState> {
  final TextEditingController _promptController = TextEditingController();

  void _sendPrompt(BuildContext context, String text) {
     if (text.trim().isEmpty) return;
     Provider.of<ChatProvider>(context, listen: false).sendMessage(text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final l10n = chatProvider.l10n;
    final isVoiceMode = chatProvider.isContinuousVoiceMode;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.deepPurple.withOpacity(0.4), Colors.transparent],
                  radius: 0.8,
                ),
              ),
              child: const Icon(Icons.bolt, size: 80, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.translate('generate_better_prompts'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('describe_prompts_subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: const Color(0xFF8F8F99),
              height: 1.4,
            ),
          ),

          if (isVoiceMode) ...[
            // ── Listening state ─────────────────────────────────────────────
            const SizedBox(height: 48),
            Center(
              child: SpinKitPulse(
                color: const Color(0xFF4A60D4),
                size: 110,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Listening...',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Speak to start your conversation',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF8F8F99),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap the stop button below to cancel',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF8F8F99).withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ] else ...[
            // ── Normal welcome state ────────────────────────────────────────
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _promptController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: l10n.translate('describe_placeholder'),
                  hintStyle: const TextStyle(color: Color(0xFF8F8F99)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF8F8F99)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onSubmitted: (text) => _sendPrompt(context, text),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _sendPrompt(context, _promptController.text),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B2E7E), Color(0xFF4A60D4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    l10n.translate('generate_prompt'),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── "or" divider ──────────────────────────────────────────────
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8F8F99),
                      fontSize: 13,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.white10, thickness: 1)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Voice mode button ─────────────────────────────────────────
            GestureDetector(
              onTap: () {
                final provider =
                    Provider.of<ChatProvider>(context, listen: false);
                provider.setContinuousVoiceMode(true);
                ChatInputField.globalKey.currentState?.startListening();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFF4A60D4), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic_none_rounded,
                        color: Color(0xFF4A60D4), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Start with Voice',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF4A60D4),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              l10n.translate('prompt_types'),
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF8F8F99),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 600 ? 4 : 2;
                final aspectRatio = width > 600 ? 4.0 : 3.0;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: aspectRatio,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildTypeCard(Icons.image, 'Image AI', Colors.blueAccent),
                    _buildTypeCard(Icons.chat, 'ChatGPT', Colors.tealAccent),
                    _buildTypeCard(Icons.campaign,
                        l10n.translate('marketing'), Colors.purpleAccent),
                    _buildTypeCard(Icons.code,
                        l10n.translate('coding'), Colors.lightBlueAccent),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              l10n.translate('try_prompts'),
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF8F8F99),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildTryPrompt(context, l10n.translate('try_prompt_1')),
            _buildTryPrompt(context, l10n.translate('try_prompt_2')),
            _buildTryPrompt(context, l10n.translate('try_prompt_3')),
            _buildTryPrompt(context, l10n.translate('try_prompt_4')),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeCard(IconData icon, String title, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTryPrompt(BuildContext context, String text) {
    return InkWell(
      onTap: () => _sendPrompt(context, text),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF8F8F99),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8F8F99),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isLast;

  const MessageBubble({super.key, required this.message, this.isLast = false});

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = Provider.of<ChatProvider>(context, listen: false).l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: Text(l10n.translate('edit'), style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<ChatProvider>(context, listen: false).editMessage(
                    message,
                    (text) {
                      ChatInputField.globalKey.currentState?.setText(text);
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.white),
                title: Text(l10n.translate('roll_back'), style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<ChatProvider>(context, listen: false).rollbackMessage(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: message.isUser ? () => _showOptionsSheet(context) : null,
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width > 800 
                    ? 600 
                    : MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? Theme.of(context).primaryColor
                      : const Color(0xFF1C1C24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imagePath != null &&
                        message.imagePath!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: message.imagePath!.startsWith('http')
                              ? Image.network(
                                  message.imagePath!,
                                  width: 250,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(color: Colors.white),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(message.imagePath!),
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    if (message.documentName != null &&
                        message.documentName!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.description, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                message.documentName!,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (message.text == '...') 
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: SpinKitThreeBounce(
                          color: Colors.white70,
                          size: 20.0,
                        ),
                      )
                    else 
                      MarkdownBody(
                        data: message.text.split('\n\n=== Document Content ===').first,
                        softLineBreak: true,
                        builders: {
                          'pre': _CopyableCodeBlockBuilder(),
                        },
                        styleSheet: MarkdownStyleSheet.fromTheme(
                          Theme.of(context),
                        ).copyWith(
                          p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                          code: GoogleFonts.sourceCodePro(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: const Color(0xFF111118),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          codeblockPadding: const EdgeInsets.all(14),
                          blockSpacing: 8,
                        ),
                      ),
                    if (!message.isUser && message.text != '...')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.copy,
                              size: 16,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: message.text),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(Provider.of<ChatProvider>(context, listen: false).l10n.translate('copied_to_clipboard')),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.share,
                              size: 16,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              Share.share(message.text);
                            },
                          ),
                          if (isLast &&
                              !message.isUser &&
                              !Provider.of<ChatProvider>(context).isResponding)
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.rotateRight,
                                size: 16,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                Provider.of<ChatProvider>(
                                  context,
                                  listen: false,
                                ).regenerateResponse();
                              },
                            ),
                        ],
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
}

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key});
  static final GlobalKey<_ChatInputFieldState> globalKey =
      GlobalKey<_ChatInputFieldState>();

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _controller = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;
  String _lastWords = '';
  String? _selectedImagePath;
  String? _selectedDocumentPath;
  String? _selectedDocumentName;

  void setText(String text) {
    _controller.text = text;
  }

  void stopListening() {
    if (_isListening) {
      _speechToText.stop();
      _lastWords = ''; 
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Do NOT initialize speech here — lazy-init on first voice mode use
    // so the OS microphone permission dialog is never shown at startup.
  }

  Future<bool> _initSpeech() async {
    if (_speechInitialized) return true;
    try {
      final result = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _onSpeechEnd();
          }
        },
        onError: (errorNotification) => debugPrint('STT error: $errorNotification'),
      );
      _speechInitialized = result;
      return result;
    } catch (e) {
      debugPrint('STT init failed: $e');
      return false;
    }
  }

  void _onSpeechEnd() {
    if (_isListening) {
      if (mounted) {
        setState(() => _isListening = false);
      } else {
        _isListening = false;
      }

      if (_lastWords.isNotEmpty || _selectedImagePath != null || _selectedDocumentPath != null) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.sendMessage(
          _lastWords,
          isVoiceInput: true,
          imagePath: _selectedImagePath,
          documentPath: _selectedDocumentPath,
          documentName: _selectedDocumentName,
        );
        _lastWords = '';
        _selectedImagePath = null;
        _selectedDocumentPath = null;
        _selectedDocumentName = null;
        _controller.clear();
      } else {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        if (chatProvider.isContinuousVoiceMode && !chatProvider.isResponding) {
          startListening();
        }
      }
    }
  }

  Future<void> startListening() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (!chatProvider.isContinuousVoiceMode) return;
    if (_isListening) return;

    var status = await Permission.microphone.status;

    if (status.isPermanentlyDenied) {
      // User permanently denied — direct them to system settings
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Microphone Permission Needed'),
            content: const Text(
              'Voice mode needs microphone access, which was permanently denied. '
              'Please enable it in your device Settings > App Permissions.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              }, child: const Text('Open Settings')),
            ],
          ),
        );
      }
      chatProvider.setContinuousVoiceMode(false);
      return;
    }

    if (!status.isGranted) {
      // Show rationale before requesting (required for Play Store compliance)
      bool proceed = true;
      if (status.isDenied && mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Microphone Access'),
            content: const Text(
              'Vakya Pro needs microphone access only while you are using Voice Mode '
              'to convert your speech to text. The microphone is never used in the background.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  proceed = false;
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
      if (!proceed) {
        chatProvider.setContinuousVoiceMode(false);
        return;
      }
      status = await Permission.microphone.request();
    }

    if (status != PermissionStatus.granted) {
      chatProvider.setContinuousVoiceMode(false);
      return;
    }

    // Lazy-init the STT engine now that permission is confirmed
    if (!_speechInitialized) {
      final ok = await _initSpeech();
      if (!ok) {
        chatProvider.setContinuousVoiceMode(false);
        return;
      }
    }

    if (chatProvider.isResponding) {
      chatProvider.stopResponding();
    }

    if (mounted) {
      setState(() {
        _isListening = true;
        _lastWords = '';
        _controller.clear();
      });
    }

    _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
      pauseFor: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1C1C24),
      child: Column(
        children: [
          if (_selectedImagePath != null)
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(_selectedImagePath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImagePath = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (_selectedDocumentName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _selectedDocumentName!,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedDocumentPath = null;
                        _selectedDocumentName = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 6, bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.image_outlined, color: Colors.white70, size: 22),
                      tooltip: 'Attach Image',
                      onPressed: () async {
                        var status = await Permission.photos.status;
                        if (status.isPermanentlyDenied) {
                           openAppSettings();
                           return;
                        }
                        if (!status.isGranted) {
                          await Permission.photos.request();
                        }
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setState(() {
                            _selectedImagePath = image.path;
                            _selectedDocumentPath = null;
                            _selectedDocumentName = null;
                          });
                        }
                      },
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.attach_file_rounded, color: Colors.white70, size: 22),
                      tooltip: 'Attach Document',
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'txt'],
                        );

                        if (result != null && result.files.single.path != null) {
                          setState(() {
                            _selectedDocumentPath = result.files.single.path;
                            _selectedDocumentName = result.files.single.name;
                            _selectedImagePath = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  onChanged: (text) {
                    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                    if (chatProvider.isContinuousVoiceMode) {
                      chatProvider.setContinuousVoiceMode(false);
                      if (_isListening) {
                        _speechToText.stop();
                        _lastWords = '';
                        setState(() {
                          _isListening = false;
                        });
                      }
                    } else if (_isListening) {
                      _speechToText.stop();
                      _lastWords = '';
                      setState(() {
                        _isListening = false;
                      });
                    } else {
                      setState(() {});
                    }
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: chatProvider.l10n.translate('type_message'),
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2A35),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: (chatProvider.isContinuousVoiceMode || chatProvider.isResponding)
                        ? const [Color(0xFF7E2020), Color(0xFFD44040)]
                        : const [Color(0xFF3B2E7E), Color(0xFF4A60D4)],
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: chatProvider.isContinuousVoiceMode
                      // State 4: voice mode active → stop (ends voice + AI)
                      ? IconButton(
                          key: const ValueKey('stop-voice'),
                          onPressed: () {
                            chatProvider.setContinuousVoiceMode(false);
                            _speechToText.stop();
                            if (chatProvider.isResponding) chatProvider.stopResponding();
                            setState(() => _isListening = false);
                          },
                          icon: const Icon(Icons.stop_rounded, color: Colors.white),
                          tooltip: 'End Voice Mode',
                        )
                      : chatProvider.isResponding
                          // State 3: AI generating → stop
                          ? IconButton(
                              key: const ValueKey('stop-ai'),
                              onPressed: () => chatProvider.stopResponding(),
                              icon: const Icon(Icons.stop_rounded, color: Colors.white),
                              tooltip: 'Stop responding',
                            )
                          : (_controller.text.trim().isNotEmpty ||
                                  _selectedImagePath != null ||
                                  _selectedDocumentPath != null)
                              // State 2: has content → send
                              ? IconButton(
                                  key: const ValueKey('send'),
                                  icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                                  onPressed: () {
                                    final text = _controller.text.trim();
                                    chatProvider.sendMessage(
                                      text,
                                      imagePath: _selectedImagePath,
                                      documentPath: _selectedDocumentPath,
                                      documentName: _selectedDocumentName,
                                    );
                                    _controller.clear();
                                    setState(() {
                                      _selectedImagePath = null;
                                      _selectedDocumentPath = null;
                                      _selectedDocumentName = null;
                                    });
                                    _lastWords = '';
                                  },
                                )
                              // State 1: default → mic / start voice mode
                              : IconButton(
                                  key: const ValueKey('mic'),
                                  icon: const Icon(Icons.mic_none_rounded, color: Colors.white),
                                  onPressed: () {
                                    chatProvider.setContinuousVoiceMode(true);
                                    startListening();
                                  },
                                  tooltip: 'Voice mode',
                                ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Always stop microphone when leaving the chat page
    if (_isListening) {
      _speechToText.stop();
      _isListening = false;
    }
    _controller.dispose();
    // Turn off continuous voice mode in provider so it doesn't restart elsewhere
    try {
      final cp = Provider.of<ChatProvider>(context, listen: false);
      if (cp.isContinuousVoiceMode) {
        cp.setContinuousVoiceMode(false);
      }
    } catch (_) {}
    super.dispose();
  }
}

class _CopyableCodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final rawText = element.textContent;
    final codeText = rawText.trimRight();
    return _CopyableCodeBlock(codeText: codeText);
  }
}

class _CopyableCodeBlock extends StatefulWidget {
  final String codeText;
  const _CopyableCodeBlock({required this.codeText});

  @override
  State<_CopyableCodeBlock> createState() => _CopyableCodeBlockState();
}

class _CopyableCodeBlockState extends State<_CopyableCodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.codeText));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'prompt',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                GestureDetector(
                  onTap: _copy,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? const Row(
                            key: ValueKey('done'),
                            children: [
                              Icon(Icons.check_rounded, size: 14, color: Colors.greenAccent),
                              SizedBox(width: 4),
                              Text('Copied', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                            ],
                          )
                        : const Row(
                            key: ValueKey('copy'),
                            children: [
                              Icon(Icons.copy_rounded, size: 14, color: Colors.white54),
                              SizedBox(width: 4),
                              Text('Copy', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              widget.codeText,
              style: GoogleFonts.sourceCodePro(
                fontSize: 13,
                color: Colors.white,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

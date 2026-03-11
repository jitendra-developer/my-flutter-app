import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'chat_provider.dart';
import 'history_page.dart';
import 'screens/pre_prompts_page.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  Widget _buildDrawer(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'User Name';

    final recentChats = chatProvider.chatHistory.take(2).toList();
    
    return Drawer(
      backgroundColor: const Color(0xFF1C1C24),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.white),
              title: const Text('New Chat', style: TextStyle(color: Colors.white, fontSize: 16)),
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
              title: const Text('Pre Prompts', style: TextStyle(color: Colors.white, fontSize: 16)),
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
              title: const Text('Recent Chats', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                    Provider.of<ChatProvider>(context, listen: false).switchChat(chat.id);
                  },
                );
              }),
            ],
            const Spacer(),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.white),
              title: Text(userName, style: const TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                // Future profile customization will be here
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFF2C2C2C),
                      title: const Text('Log Out', style: TextStyle(color: Colors.white)),
                      content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Yes', style: TextStyle(color: Colors.redAccent)),
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
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              if (provider.messages.isEmpty) return const SizedBox.shrink();
              return ChatInputField(key: ChatInputField.globalKey);
            },
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo/Icon
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                // A subtle gradient background for the icon area to simulate the glowing 3D asset
                gradient: RadialGradient(
                  colors: [Colors.deepPurple.withOpacity(0.4), Colors.transparent],
                  radius: 0.8,
                ),
              ),
              child: const Icon(Icons.bolt, size: 80, color: Colors.amber), 
            ),
          ),
          const SizedBox(height: 24),
          // Heading
          Text(
            'Generate Better AI Prompts',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Subheading
          Text(
            'Describe what you want and get optimized\nprompts for any AI tool.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: const Color(0xFF8F8F99),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          // Input field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              controller: _promptController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Describe the prompt you want to create...',
                hintStyle: TextStyle(color: Color(0xFF8F8F99)),
                prefixIcon: Icon(Icons.search, color: Color(0xFF8F8F99)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onSubmitted: (text) => _sendPrompt(context, text),
            ),
          ),
          const SizedBox(height: 16),
          // Generate button
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
                  'Generate Prompt',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Prompt Types Title
          Text(
            'Prompt Types',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF8F8F99),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.0,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildTypeCard(Icons.image, 'Image AI', Colors.blueAccent),
              _buildTypeCard(Icons.chat, 'ChatGPT', Colors.tealAccent),
              _buildTypeCard(Icons.campaign, 'Marketing', Colors.purpleAccent),
              _buildTypeCard(Icons.code, 'Coding', Colors.lightBlueAccent),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Try prompts',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF8F8F99),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _buildTryPrompt(context, 'Create a prompt for writing viral tweets'),
          _buildTryPrompt(context, 'Generate Midjourney image prompt'),
          _buildTryPrompt(context, 'Create a marketing prompt for product launch'),
          _buildTryPrompt(context, 'Generate AI prompt for a blog outline'),
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
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Edit',
                  style: TextStyle(color: Colors.white),
                ),
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
                title: const Text(
                  'Roll Back',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  ).rollbackMessage(message);
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
                maxWidth: MediaQuery.of(context).size.width * 0.70,
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
                    MarkdownBody(
                      data: message.text.split('\n\n=== Document Content ===').first,
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                    ),
                    if (!message.isUser)
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
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
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
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _onSpeechEnd();
        }
      },
      onError: (errorNotification) => print('error: $errorNotification'),
    );
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
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }

    if (status != PermissionStatus.granted) {
      chatProvider.setContinuousVoiceMode(false);
      return;
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
          if (chatProvider.isResponding)
            ElevatedButton(
              onPressed: () {
                chatProvider.stopResponding();
              },
              child: const Text('Stop Responding'),
            ),
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
              // Media & Document attachment buttons
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined, color: Colors.white70, size: 22),
                      tooltip: 'Attach Image',
                      onPressed: () async {
                        var status = await Permission.photos.status;
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
              // Expanding Text Input
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
                      _lastWords = ''; // discard spoken words
                      setState(() {
                        _isListening = false;
                      });
                    }
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Message Vakya Pro...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2A35),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Voice / Send buttons
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B2E7E), Color(0xFF4A60D4)],
                  ),
                ),
                child: chatProvider.isContinuousVoiceMode
                  ? IconButton(
                      onPressed: () {
                        chatProvider.setContinuousVoiceMode(false);
                        _speechToText.stop();
                        if (chatProvider.isResponding) chatProvider.stopResponding();
                        setState(() {
                          _isListening = false;
                        });
                      },
                      icon: const Icon(Icons.stop_rounded, color: Colors.redAccent),
                      tooltip: 'End Voice Mode',
                    )
                  : IconButton(
                      icon: _controller.text.trim().isEmpty && _selectedImagePath == null && _selectedDocumentPath == null
                          ? const Icon(Icons.mic_none_rounded, color: Colors.white)
                          : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                      onPressed: () {
                        if (_controller.text.trim().isEmpty && _selectedImagePath == null && _selectedDocumentPath == null) {
                           // Voice mode
                           chatProvider.setContinuousVoiceMode(true);
                           startListening();
                        } else {
                          // Send Message
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
                        }
                      },
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
    _controller.dispose();
    super.dispose();
  }
}

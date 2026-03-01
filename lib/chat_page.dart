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
      backgroundColor: const Color(0xFF1E1E1E),
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
      backgroundColor: const Color(0xFF121212),
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
          'Vakya AI',
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
                  final userName = Supabase.instance.client.auth.currentUser?.userMetadata?['full_name']?.split(' ').first ?? 'User';
                  return Center(
                    child: Text(
                      'Welcome Again $userName',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                      ),
                    ),
                  );
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
          ChatInputField(key: ChatInputField.globalKey),
        ],
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
      backgroundColor: const Color(0xFF1E1E1E),
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
                      ? Colors.deepPurple
                      : const Color(0xFF1E1E1E),
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
      color: const Color(0xFF1E1E1E),
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
            children: [
              IconButton(
                icon: const Icon(Icons.image, color: Colors.white70),
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
                icon: const Icon(Icons.attach_file, color: Colors.white70),
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
              Expanded(
                child: TextField(
                  controller: _controller,
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
                    hintText: 'Send a message',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2C),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (chatProvider.isContinuousVoiceMode)
                TextButton(
                  onPressed: () {
                    chatProvider.setContinuousVoiceMode(false);
                    _speechToText.stop();
                    if (chatProvider.isResponding) chatProvider.stopResponding();
                    setState(() {
                      _isListening = false;
                    });
                  },
                  child: const Text(
                    'End',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.graphic_eq, color: Colors.white),
                  onPressed: () {
                    chatProvider.setContinuousVoiceMode(true);
                    startListening();
                  },
                ),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.paperPlane,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_controller.text.isNotEmpty ||
                      _selectedImagePath != null || _selectedDocumentPath != null) {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty || _selectedImagePath != null || _selectedDocumentPath != null) {
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
                    }
                    _lastWords = '';
                  }
                },
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

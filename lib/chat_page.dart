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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Vakya AI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).createNewChat();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            // The GoRouter's refreshListenable will handle the navigation.
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );
              } else if (value == 'pre_prompts') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrePromptsPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'pre_prompts',
                child: Text('Pre Prompts'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Log out'),
              ),
            ],
            icon: const FaIcon(FontAwesomeIcons.ellipsis, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
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
                          child: Image.file(
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
                      data: message.text,
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
      }
    }
  }

  Future<void> _toggleListening(ChatProvider chatProvider) async {
    if (_isListening) {
      // End listening immediately
      _speechToText.stop();
      if (chatProvider.isResponding) {
        chatProvider.stopResponding();
      }
      _onSpeechEnd();
    } else {
      // Start listening
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      if (status != PermissionStatus.granted) {
        return;
      }

      // Stop any AI response before we start listening
      if (chatProvider.isResponding) {
        chatProvider.stopResponding();
      }

      setState(() {
        _isListening = true;
        _lastWords = '';
        _controller.clear();
      });

      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
        pauseFor: const Duration(seconds: 5), // Increased to give the user more thinking time
      );
    }
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
                    if (_isListening) {
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
              if (_isListening)
                TextButton(
                  onPressed: () => _toggleListening(chatProvider),
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
                  onPressed: () => _toggleListening(chatProvider),
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

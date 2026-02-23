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
import 'chat_provider.dart';

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
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                    return MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          const ChatInputField(),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: message.isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!message.isUser)
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/logo.png'),
            radius: 20,
          ),
        Flexible(
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
                MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        p: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
                          Clipboard.setData(ClipboardData(text: message.text));
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
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChatInputField extends StatefulWidget {
  const ChatInputField({super.key});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final _controller = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

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

      if (_lastWords.isNotEmpty) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        chatProvider.sendMessage(_lastWords);
        _lastWords = '';
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
        pauseFor: const Duration(seconds: 3),
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
            )
          else if (chatProvider.messages.isNotEmpty &&
              !chatProvider.messages.last.isUser)
            ElevatedButton(
              onPressed: () {
                chatProvider.regenerateResponse();
              },
              child: const Text('Regenerate Response'),
            ),
          Row(
            children: [
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
                  if (_controller.text.isNotEmpty) {
                    // Send manually and reset listening state text if needed
                    chatProvider.sendMessage(_controller.text);
                    _controller.clear();
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

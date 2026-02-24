import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _isResponding = false;
  OpenAI? _openAI;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  final List<String> _ttsQueue = [];
  bool _isProcessingQueue = false;

  List<ChatSession> _chatHistory = [];
  String? _currentSessionId;

  List<ChatSession> get chatHistory => _chatHistory;

  ChatProvider() {
    _openAI = OpenAI.instance;
    _initTts();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('chat_history');
    if (historyJson != null) {
      final List decoded = jsonDecode(historyJson);
      _chatHistory = decoded.map((e) => ChatSession.fromJson(e)).toList();
    }
    if (_chatHistory.isEmpty) {
      createNewChat();
    } else {
      _currentSessionId = _chatHistory.first.id;
      _messages = List.from(_chatHistory.first.messages);
    }
    notifyListeners();
  }

  Future<void> _saveChats() async {
    if (_currentSessionId != null) {
      final index = _chatHistory.indexWhere((s) => s.id == _currentSessionId);
      if (index != -1) {
        _chatHistory[index].messages = List.from(_messages);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_chatHistory.map((e) => e.toJson()).toList());
    await prefs.setString('chat_history', encoded);
  }

  void createNewChat() {
    if (_isResponding) stopResponding();
    final newSession = ChatSession(
      id: DateTime.now().toIso8601String(),
      title: 'New Chat',
      messages: [],
    );
    _chatHistory.insert(0, newSession);
    _currentSessionId = newSession.id;
    _messages = [];
    _saveChats();
    notifyListeners();
  }

  void switchChat(String sessionId) {
    if (_isResponding) stopResponding();
    final session = _chatHistory.firstWhere((s) => s.id == sessionId);
    _currentSessionId = session.id;
    _messages = List.from(session.messages);
    notifyListeners();
  }

  void deleteChat(String sessionId) {
    _chatHistory.removeWhere((s) => s.id == sessionId);
    if (_currentSessionId == sessionId) {
      if (_chatHistory.isNotEmpty) {
        switchChat(_chatHistory.first.id);
      } else {
        createNewChat();
      }
    } else {
      _saveChats();
      notifyListeners();
    }
  }

  Future<void> _generateChatTitle(String prompt) async {
    if (_currentSessionId == null) return;
    try {
      final response = await _openAI!.chat.create(
        model: 'gpt-3.5-turbo',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                "Summarize this in 3 to 5 words: $prompt",
              ),
            ],
          ),
        ],
      );
      final title =
          response.choices.first.message.content?.first?.text?.trim() ??
          "New Chat";

      final index = _chatHistory.indexWhere((s) => s.id == _currentSessionId);
      if (index != -1) {
        _chatHistory[index].title = title.replaceAll('"', '');
        _saveChats();
        notifyListeners();
      }
    } catch (e) {
      developer.log('Title generation failed', error: e);
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
  }

  Future<void> _processTtsQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    while (_ttsQueue.isNotEmpty && _isResponding) {
      final text = _ttsQueue.removeAt(0);
      if (text.trim().isNotEmpty) {
        _isSpeaking = true;
        await _flutterTts.speak(text.trim());
        _isSpeaking = false;
      }
    }
    _isProcessingQueue = false;
  }

  List<Message> get messages => _messages;
  bool get isResponding => _isResponding;

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void startResponding() {
    _isResponding = true;
    notifyListeners();
  }

  void stopResponding() {
    _isResponding = false;
    _ttsQueue.clear();
    _isProcessingQueue = false;
    _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  // Builds the list of messages to be sent to the OpenAI API
  List<OpenAIChatCompletionChoiceMessageModel> _buildMessageHistory() {
    return _messages.map((message) {
      final contentItems =
          <OpenAIChatCompletionChoiceMessageContentItemModel>[];

      if (message.text.isNotEmpty) {
        contentItems.add(
          OpenAIChatCompletionChoiceMessageContentItemModel.text(message.text),
        );
      }

      if (message.imagePath != null && message.imagePath!.isNotEmpty) {
        final bytes = File(message.imagePath!).readAsBytesSync();
        final base64Image = base64Encode(bytes);
        contentItems.add(
          OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
            "data:image/jpeg;base64,$base64Image",
          ),
        );
      }

      return OpenAIChatCompletionChoiceMessageModel(
        content: contentItems.isNotEmpty
            ? contentItems
            : [OpenAIChatCompletionChoiceMessageContentItemModel.text("")],
        role: message.isUser
            ? OpenAIChatMessageRole.user
            : OpenAIChatMessageRole.assistant,
      );
    }).toList();
  }

  Future<void> sendMessage(
    String text, {
    bool isVoiceInput = false,
    String? imagePath,
  }) async {
    final userMessage = Message(text: text, isUser: true, imagePath: imagePath);
    addMessage(userMessage);

    if (_messages.length == 1 && text.isNotEmpty) {
      _generateChatTitle(text);
    }

    startResponding();

    // Create an empty AI message that we will stream into
    final aiMessageIndex = _messages.length;
    _messages.add(Message(text: '', isUser: false));
    notifyListeners();

    try {
      final stream = _openAI!.chat.createStream(
        model: 'gpt-4o',
        temperature: 0.9,
        maxTokens: 1000,
        messages: _buildMessageHistory(),
      );

      String fullResponse = '';
      String currentSentenceBuffer = '';

      await for (final chunk in stream) {
        if (!_isResponding) break; // Early stop check

        final content = chunk.choices.first.delta.content;

        if (content != null && content.isNotEmpty) {
          final textPart = content.first?.text ?? '';
          fullResponse += textPart;

          // Update UI
          _messages[aiMessageIndex] = Message(
            text: fullResponse,
            isUser: false,
          );
          notifyListeners();

          // TTS streaming logc using basic punctuation breaks
          if (isVoiceInput) {
            currentSentenceBuffer += textPart;
            final splitPattern = RegExp(r'(?<=[.!?])\s+|\n');
            if (currentSentenceBuffer.contains(splitPattern)) {
              final parts = currentSentenceBuffer.split(splitPattern);
              for (int i = 0; i < parts.length - 1; i++) {
                if (parts[i].trim().isNotEmpty) {
                  _ttsQueue.add(parts[i].trim());
                }
              }
              currentSentenceBuffer = parts.last;
              _processTtsQueue();
            }
          }
        }
      }

      // Speak any remaining loose text at the end of the stream
      if (isVoiceInput &&
          _isResponding &&
          currentSentenceBuffer.trim().isNotEmpty) {
        _ttsQueue.add(currentSentenceBuffer.trim());
        _processTtsQueue();
      }

      _saveChats(); // Save final AI response
    } catch (e, s) {
      developer.log(
        'Error sending message to OpenAI',
        error: e,
        stackTrace: s,
        name: 'ChatProvider',
      );
      _messages[aiMessageIndex] = Message(
        text: 'Error: ${e.toString()}',
        isUser: false,
      );
      notifyListeners();
    }

    // Don't stopResponding if we are just waiting for TTS to finish naturally,
    // but we do flip the boolean to allow the user to send another message visually.
    _isResponding = false;
    notifyListeners();
  }

  Future<void> regenerateResponse() async {
    if (_messages.isEmpty || _isResponding) return;

    // Find the last user message to resend
    final lastUserMessageIndex = _messages.lastIndexWhere((m) => m.isUser);
    if (lastUserMessageIndex == -1)
      return; // No user message to regenerate from

    // Remove all AI messages that came after the last user message
    _messages.removeRange(lastUserMessageIndex + 1, _messages.length);

    final lastUserMessageText = _messages[lastUserMessageIndex].text;
    // We are not adding the user message again, just sending it for response
    // so remove it temporarily and add it back after send
    _messages.removeAt(lastUserMessageIndex);

    notifyListeners(); // Update UI to show that previous AI messages are gone

    await sendMessage(
      lastUserMessageText,
      isVoiceInput: false,
    ); // Assume text on regen for simplicity
  }

  void editMessage(Message message, Function(String) onEdit) {
    if (_isResponding) return;

    final index = _messages.indexOf(message);
    if (index == -1 || !message.isUser) return;

    // Remove this message and all subsequent messages
    _messages.removeRange(index, _messages.length);
    notifyListeners();

    onEdit(message.text);
  }

  Future<void> rollbackMessage(Message message) async {
    if (_isResponding) return;

    final index = _messages.indexOf(message);
    if (index == -1 || !message.isUser) return;

    // Remove all messages AFTER this message
    if (index + 1 < _messages.length) {
      _messages.removeRange(index + 1, _messages.length);
    }

    final textToSend = message.text;
    // Remove the message itself so we can 'resend' it freshly
    _messages.removeAt(index);
    _saveChats();
    notifyListeners();

    await sendMessage(textToSend, isVoiceInput: false);
  }
}

class ChatSession {
  final String id;
  String title;
  List<Message> messages;

  ChatSession({required this.id, required this.title, required this.messages});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final String? imagePath;

  Message({required this.text, required this.isUser, this.imagePath});

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'imagePath': imagePath,
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      imagePath: json['imagePath'] as String?,
    );
  }
}

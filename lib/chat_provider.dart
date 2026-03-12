import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import 'package:myapp/services/api_service.dart';
import 'chat_page.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _isResponding = false;
  final ApiService _apiService = ApiService();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  final List<String> _ttsQueue = [];
  bool _isProcessingQueue = false;

  bool _isContinuousVoiceMode = false;
  bool get isContinuousVoiceMode => _isContinuousVoiceMode;
  bool _isStreamingText = false;

  void setContinuousVoiceMode(bool value) {
    _isContinuousVoiceMode = value;
    notifyListeners();
  }

  List<ChatSession> _chatHistory = [];
  String? _currentSessionId;

  List<ChatSession> get chatHistory => _chatHistory;

  ChatProvider() {
    _initTts();
    _loadChats(); // Load natively if token exists
  }

  void initializeAfterAuth() {
    _loadChats();
  }

  void clearOnLogout() {
    _chatHistory.clear();
    _messages.clear();
    _currentSessionId = null;
    notifyListeners();
  }

  Future<void> _loadChats() async {
    try {
      if (!await _apiService.hasToken()) return;
      
      final data = await _apiService.getChatSessions();
      _chatHistory = data.map((e) => ChatSession.fromJson(e)).toList();
      _chatHistory.removeWhere((s) => s.messages.length < 2);

      createNewChat();
      notifyListeners();
    } catch (e) {
      developer.log('Error loading chats from API', error: e);
    }
  }

  Future<void> _saveChats() async {
    if (!await _apiService.hasToken()) return;

    if (_currentSessionId != null) {
      final index = _chatHistory.indexWhere((s) => s.id == _currentSessionId);
      if (index != -1) {
        _chatHistory[index].messages = List.from(_messages);
      }
    }

    final chatsToSave = _chatHistory.where((e) => e.messages.length >= 2).toList();
    
    try {
      for (final chat in chatsToSave) {
        // Simple logic: Assuming the backend handles saving or creating via these endpoints.
        // We will pass the messages JSON. If it's a UUID, we likely need to POST unless we track backend IDs.
        // For now, attempting PUT, if fails, fallback to POST.
        try {
           await _apiService.updateChatSession(chat.id, chat.title, chat.messages.map((m) => m.toJson()).toList());
        } catch (_) {
           final res = await _apiService.createChatSession(chat.title, chat.messages.map((m) => m.toJson()).toList());
           // Update local ID to match backend if they return one
           if (res['id'] != null) chat.id = res['id'].toString();
        }
      }
    } catch (e) {
      developer.log('Error saving chats to API', error: e);
    }
  }

  void createNewChat() {
    if (_isResponding) stopResponding();

    _chatHistory.removeWhere((s) => s.messages.length < 2 && s.id != _currentSessionId);
    if (_currentSessionId != null && _messages.length < 2) {
      _chatHistory.removeWhere((s) => s.id == _currentSessionId);
    }

    final newSession = ChatSession(
      id: const Uuid().v4(),
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

    if (_currentSessionId != null) {
      if (_messages.length < 2) {
        _chatHistory.removeWhere((s) => s.id == _currentSessionId);
      } else {
        final index = _chatHistory.indexWhere((s) => s.id == _currentSessionId);
        if (index != -1) {
          _chatHistory[index].messages = List.from(_messages);
        }
      }
    }

    final session = _chatHistory.firstWhere((s) => s.id == sessionId, orElse: () => _chatHistory.first);
    _currentSessionId = session.id;
    _messages = List.from(session.messages);
    notifyListeners();
  }

  Future<void> deleteChat(String sessionId) async {
    _chatHistory.removeWhere((s) => s.id == sessionId);
    if (_currentSessionId == sessionId) {
      if (_chatHistory.isNotEmpty) {
        switchChat(_chatHistory.first.id);
      } else {
        createNewChat();
      }
    } else {
      notifyListeners();
    }
    
    try {
      await _apiService.deleteChatSession(sessionId);
    } catch (e) {
      developer.log('Failed to delete chat from API', error: e);
    }
  }

  Future<void> _generateChatTitle() async {
    if (_currentSessionId == null || _messages.length < 2) return;
    try {
      final contextText = _messages.take(2).map((m) => "${m.isUser ? 'User' : 'AI'}: ${m.text}").join('\n');
      
      final response = await _apiService.aiChat([
        {
          "role": "user",
          "content": "Generate a clear, brief 3 to 5 word title for this conversation. Return ONLY the title, no quotes or extra text.\n\nConversation:\n$contextText"
        }
      ]);
      
      final title = response['content']?.toString().trim() ?? "New Chat";

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
    _checkResponseComplete();
  }

  List<Message> get messages => _messages;
  bool get isResponding => _isResponding;

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void startResponding() {
    _isResponding = true;
    _isStreamingText = true;
    notifyListeners();
  }

  void stopResponding() {
    _isResponding = false;
    _isStreamingText = false;
    _ttsQueue.clear();
    _isProcessingQueue = false;
    _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  // Builds the list of messages to be sent to the API
  List<Map<String, dynamic>> _buildMessageHistory({bool forVoice = false}) {
    final List<Map<String, dynamic>> apiMessages = [];

    // System prompt for persona and concise responses
    String systemPromptText = """You are Vakya Pro, a prompt generation assistant.

      Your ONLY job is to help users create high quality prompts for AI tools.

      IMPORTANT RULES:
      - Never generate images.
      - Never say you created an image.
      - Only generate prompts.
      - If a user asks you to generate an image, you must reply EXACTLY with: "sorry, i cant generate images. Use only for prompt generation."

      Conversation style:
      You guide users step-by-step like a friendly interviewer.

      If the user request is vague:
      Ask ONE simple question at a time.

      Do NOT ask many questions at once.

      Example flow:

      User: I want to create a logo

      Assistant: Sure. What is the name of the company?

      User: Vakya Pro

      Assistant: Great. What does the company do?

      User: It helps people generate prompts.

      Assistant: Nice. Do you prefer a style such as modern, minimal, or futuristic?

      After collecting enough information:
      Generate a clear prompt the user can use in AI tools.

      When generating the final result:
      First write a short explanation sentence.
      Then ALWAYS wrap the prompt itself in a markdown code block using triple backticks.

      Example format you MUST follow:

      Here is a prompt you can use:

      ```
      Transform my photo into a cinematic portrait of a Rajput king wearing a royal Rajput king dress. The setting should be a vibrant palace background, showcasing rich colors and intricate details that emphasize the grandeur and regal nature of the character.
      ```

      You can take this prompt and use it with your desired AI tool!""";

    
    if (forVoice) {
      systemPromptText +=
          " Your responses are being spoken via Text-to-Speech, so write like you are having a spoken conversation. Use brief sentences, natural pauses, and avoid code blocks, tables, or long lists unless explicitly requested.";
    }

    apiMessages.add({
      'role': 'system',
      'content': systemPromptText,
    });

    apiMessages.addAll(_messages.map((message) {
      String finalContent = message.text;

      // Note: Backend might need specific format for base64 images, 
      // but assuming standard text content for now per docs. 
      // If image extraction is needed, append it if valid.
      if (message.imagePath != null && message.imagePath!.isNotEmpty) {
        final bytes = File(message.imagePath!).readAsBytesSync();
        final base64Image = base64Encode(bytes);
        finalContent += "\n\n[Attached Image (Base64): data:image/jpeg;base64,$base64Image]";
      }

      return {
        'role': message.isUser ? 'user' : 'assistant',
        'content': finalContent,
      };
    }));

    return apiMessages;
  }

  Future<bool> _isImageGenerationIntent(String prompt, String? imagePath) async {
    // Image generation disabled as we only want to generate prompts
    return false;
  }

  Future<void> sendMessage(
    String text, {
    bool isVoiceInput = false,
    String? imagePath,
    String? documentPath,
    String? documentName,
  }) async {
    String finalPromptText = text;

    // Check if there is a document to parse
    if (documentPath != null && documentPath.isNotEmpty) {
      try {
        String extractedText = '';
        final file = File(documentPath);
        
        if (documentName?.toLowerCase().endsWith('.pdf') == true) {
          final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
          extractedText = PdfTextExtractor(document).extractText();
          document.dispose();
        } else if (documentName?.toLowerCase().endsWith('.txt') == true) {
          extractedText = file.readAsStringSync();
        }

        if (extractedText.isNotEmpty) {
          if (finalPromptText.isEmpty) {
            finalPromptText = "Please analyze this document and tell me what is inside, and give some insights:\n\n=== Document Content ===\n$extractedText";
          } else {
            finalPromptText = "$finalPromptText\n\n=== Document Content ===\n$extractedText";
          }
        }
      } catch (e) {
        developer.log('Failed to extract text from document', error: e);
      }
    }

    final userMessage = Message(
      text: finalPromptText,
      isUser: true,
      imagePath: imagePath,
      documentPath: documentPath,
      documentName: documentName,
    );
    addMessage(userMessage);

    startResponding();

    // Show a temporary loading indicator for processing intent or generation
    final aiMessageIndex = _messages.length;
    _messages.add(Message(text: '...', isUser: false));
    notifyListeners();

    bool isImageRequest = await _isImageGenerationIntent(text, imagePath);

    try {
      if (isImageRequest) {
        // Handle Image Generation via Backend
        _messages[aiMessageIndex] = Message(
          text: 'Generating image... Please wait.',
          isUser: false,
        );
        notifyListeners();

        final response = await _apiService.generateImage(finalPromptText);
        final imageUrl = response['url'] ?? '';

        _messages[aiMessageIndex] = Message(
          text: 'Here is your generated image:',
          isUser: false,
          imagePath: imageUrl,
        );
        notifyListeners();

        if (isVoiceInput) {
           _ttsQueue.add('I have generated the image for you.');
           _processTtsQueue();
        }

      } else {
        // Standard Text AI Chat (Non-stream since we skipped SSE implementation for now)
        final history = _buildMessageHistory(forVoice: isVoiceInput);
        final response = await _apiService.aiChat(history);
        
        final aiText = response['content']?.toString() ?? 'Error: Invalid response format';

        _messages[aiMessageIndex] = Message(
          text: aiText,
          isUser: false,
        );
        notifyListeners();

        if (isVoiceInput) {
          final splitPattern = RegExp(r'(?<=[.!?])\s+|\n');
          final parts = aiText.split(splitPattern);
          for (final part in parts) {
            if (part.trim().isNotEmpty) {
              _ttsQueue.add(part.trim());
            }
          }
          _processTtsQueue();
        }
      }

      _saveChats();

      if (_messages.length == 2) {
        _generateChatTitle();
      }
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
    } finally {
      _isStreamingText = false;
      _checkResponseComplete();
    }
  }

  void _checkResponseComplete() {
    if (!_isStreamingText && _ttsQueue.isEmpty && !_isSpeaking) {
      if (_isResponding) {
        _isResponding = false;
        notifyListeners();
      }
      if (_isContinuousVoiceMode) {
        _triggerStartListening();
      }
    }
  }

  void _triggerStartListening() {
    Future.microtask(() {
      if (ChatInputField.globalKey.currentState != null) {
        ChatInputField.globalKey.currentState!.startListening();
      }
    });
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
  String id;
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
          .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final String? imagePath;
  final String? documentPath;
  final String? documentName;

  Message({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.documentPath,
    this.documentName,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'imagePath': imagePath,
    'documentPath': documentPath,
    'documentName': documentName,
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      imagePath: json['imagePath'] as String?,
      documentPath: json['documentPath'] as String?,
      documentName: json['documentName'] as String?,
    );
  }
}

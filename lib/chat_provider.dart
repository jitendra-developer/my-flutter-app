import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import 'chat_page.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  bool _isResponding = false;
  OpenAI? _openAI;
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

  final _supabase = Supabase.instance.client;
  
  ChatProvider() {
    _openAI = OpenAI.instance;
    _initTts();
    _initAuthListener();
  }

  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _loadChats();
      } else {
        _chatHistory.clear();
        _messages.clear();
        _currentSessionId = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadChats() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      final response = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      _chatHistory = data.map((e) => ChatSession.fromJson(e)).toList();
      _chatHistory.removeWhere((s) => s.messages.length < 2);

      createNewChat();
      notifyListeners();
    } catch (e) {
      developer.log('Error loading chats from Supabase', error: e);
    }
  }

  Future<void> _saveChats() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    if (_currentSessionId != null) {
      final index = _chatHistory.indexWhere((s) => s.id == _currentSessionId);
      if (index != -1) {
        _chatHistory[index].messages = List.from(_messages);
      }
    }

    final chatsToSave = _chatHistory.where((e) => e.messages.length >= 2).toList();
    
    try {
      for (final chat in chatsToSave) {
        await _supabase.from('chat_sessions').upsert({
          'id': chat.id,
          'user_id': currentUser.id,
          'title': chat.title,
          'messages': chat.messages.map((m) => m.toJson()).toList(),
          // created_at is handled by default on insert
        });
      }
    } catch (e) {
      developer.log('Error saving chats to Supabase', error: e);
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
      await _supabase.from('chat_sessions').delete().eq('id', sessionId);
    } catch (e) {
      developer.log('Failed to delete chat from Supabase', error: e);
    }
  }

  Future<void> _generateChatTitle() async {
    if (_currentSessionId == null || _messages.length < 2) return;
    try {
      final contextText = _messages.take(2).map((m) => "${m.isUser ? 'User' : 'AI'}: ${m.text}").join('\n');
      final response = await _openAI!.chat.create(
        model: 'gpt-3.5-turbo',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                "Generate a clear, brief 3 to 5 word title for this conversation. Return ONLY the title, no quotes or extra text.\n\nConversation:\n$contextText",
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

  // Builds the list of messages to be sent to the OpenAI API
  List<OpenAIChatCompletionChoiceMessageModel> _buildMessageHistory(
      {bool forVoice = false}) {
    final List<OpenAIChatCompletionChoiceMessageModel> apiMessages = [];

    // System prompt for persona and concise responses
    String systemPromptText =
        "You are Vakya AI, a helpful, friendly, and knowledgeable assistant. Provide accurate and concise answers. Keep responses well-structured but do not use complex markdown that is difficult to speak aloud.";
    if (forVoice) {
      systemPromptText +=
          " Your responses are being spoken via Text-to-Speech, so write like you are having a spoken conversation. Use brief sentences, natural pauses, and avoid code blocks, tables, or long lists unless explicitly requested.";
    }

    apiMessages.add(
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPromptText)
        ],
      ),
    );

    apiMessages.addAll(_messages.map((message) {
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
    }));

    return apiMessages;
  }

  Future<bool> _isImageGenerationIntent(String prompt, String? imagePath) async {
    if (imagePath != null && prompt.toLowerCase().contains('modify')) return true;
    
    // Quick keyword fallback
    final lowerPrompt = prompt.toLowerCase();
    if (lowerPrompt.startsWith('generate an image') || 
        lowerPrompt.startsWith('draw a') || 
        lowerPrompt.startsWith('create an image')) {
      return true;
    }

    try {
      final response = await _openAI!.chat.create(
        model: 'gpt-3.5-turbo',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                "You are an intent classifier. Does the user want to generate, draw, or create a new original image based on their prompt? "
                "Respond strictly with YES or NO. Do not explain. If they are just asking a question about an image, reply NO."
              )
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)],
          ),
        ],
        temperature: 0.0,
      );
      final text = response.choices.first.message.content?.first?.text?.trim().toUpperCase();
      return text != null && text.contains('YES');
    } catch (e) {
      return false;
    }
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
        // DALL-E 3 Image Generation or Modification
        _messages[aiMessageIndex] = Message(
          text: 'Generating image... Please wait.',
          isUser: false,
        );
        notifyListeners();

        final response = await _openAI!.image.create(
          prompt: finalPromptText,
          model: "dall-e-3",
          n: 1,
          size: OpenAIImageSize.size1024,
          responseFormat: OpenAIImageResponseFormat.url,
        );

        final imageUrl = response.data.first.url;

        _messages[aiMessageIndex] = Message(
          text: 'Here is your generated image:',
          isUser: false,
          imagePath: imageUrl, // Storing remote URL instead of local path for simplicity in display
        );
        notifyListeners();

        if (isVoiceInput) {
           _ttsQueue.add('I have generated the image for you.');
           _processTtsQueue();
        }

      } else {
        // Standard Text/Vision Completion via GPT-4o
        final stream = _openAI!.chat.createStream(
          model: 'gpt-4o',
          temperature: 0.7,
          maxTokens: 1000,
          messages: _buildMessageHistory(forVoice: isVoiceInput),
        );

        String fullResponse = '';
        String currentSentenceBuffer = '';

        await for (final chunk in stream) {
          if (!_isResponding) break;

          final content = chunk.choices.first.delta.content;

          if (content != null && content.isNotEmpty) {
            final textPart = content.first?.text ?? '';
            fullResponse += textPart;

            _messages[aiMessageIndex] = Message(
              text: fullResponse,
              isUser: false,
            );
            notifyListeners();

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

        if (isVoiceInput && _isResponding && currentSentenceBuffer.trim().isNotEmpty) {
          _ttsQueue.add(currentSentenceBuffer.trim());
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

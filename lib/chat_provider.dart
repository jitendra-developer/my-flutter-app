import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  bool _isResponding = false;

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
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final userMessage = Message(text: text, isUser: true);
    addMessage(userMessage);

    startResponding();

    try {
      final response = await OpenAI.instance.chat.create(
        model: 'gpt-3.5-turbo',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                messages.map((m) => m.text).join('\n') + text,
              ),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      final content = response.choices.first.message.content;
      final responseText = (content != null && content.isNotEmpty)
          ? content.first.text ?? 'Sorry, I could not generate a response.'
          : 'Sorry, I could not generate a response.';

      final aiMessage = Message(text: responseText, isUser: false);
      addMessage(aiMessage);
    } catch (e) {
      final errorMessage = Message(text: 'Error: $e', isUser: false);
      addMessage(errorMessage);
    }

    stopResponding();
  }

  Future<void> regenerateResponse() async {
    if (_messages.isNotEmpty && !_isResponding) {
      final lastUserMessage = _messages.lastWhere((m) => m.isUser);
      _messages.removeWhere((m) => !m.isUser);
      await sendMessage(lastUserMessage.text);
    }
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

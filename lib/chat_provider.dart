import 'package:flutter/material.dart';
// import 'package:dart_openai/dart_openai.dart';

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  bool _isResponding = false;
  // OpenAI? _openAI;

  ChatProvider() {
    // _openAI = OpenAI.instance;
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
    notifyListeners();
  }

  // Builds the list of messages to be sent to the OpenAI API
  // List<OpenAIChatCompletionChoiceMessageModel> _buildMessageHistory() {
  //   return _messages.map((message) {
  //     return OpenAIChatCompletionChoiceMessageModel(
  //       content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(message.text)],
  //       role: message.isUser ? OpenAIChatMessageRole.user : OpenAIChatMessageRole.assistant,
  //     );
  //   }).toList();
  // }

  Future<void> sendMessage(String text) async {
    final userMessage = Message(text: text, isUser: true);
    addMessage(userMessage);
    notifyListeners();

    // startResponding();

    // try {
    //   // final response = await _openAI!.chat.create(
    //   //   model: 'gpt-3.5-turbo',
    //   //   messages: _buildMessageHistory(),
    //   // );

    //   // final content = response.choices.first.message.content;
    //   // final responseText = (content != null && content.isNotEmpty)
    //   //     ? content.first.text ?? 'Sorry, I could not generate a response.'
    //   //     : 'Sorry, I could not generate a response.';

    //   // final aiMessage = Message(text: responseText, isUser: false);
    //   // addMessage(aiMessage);
    // } catch (e, s) {
    //   developer.log('Error sending message to OpenAI', error: e, stackTrace: s, name: 'ChatProvider');
    //   final errorMessage = Message(text: 'Error: Could not get a response from the AI. Please check your API key and network connection.', isUser: false);
    //   addMessage(errorMessage);
    // }

    // stopResponding();
  }

  Future<void> regenerateResponse() async {
    // if (_messages.isEmpty || _isResponding) return;

    // // Find the last user message to resend
    // final lastUserMessageIndex = _messages.lastIndexWhere((m) => m.isUser);
    // if (lastUserMessageIndex == -1) return; // No user message to regenerate from

    // // Remove all AI messages that came after the last user message
    // _messages.removeRange(lastUserMessageIndex + 1, _messages.length);
    
    // final lastUserMessageText = _messages[lastUserMessageIndex].text;
    // // We are not adding the user message again, just sending it for response
    // // so remove it temporarily and add it back after send
    // _messages.removeAt(lastUserMessageIndex);
    
    // notifyListeners(); // Update UI to show that previous AI messages are gone

    // await sendMessage(lastUserMessageText);
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

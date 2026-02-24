import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chat_provider.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'Chat History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          final history = provider.chatHistory;
          if (history.isEmpty) {
            return const Center(
              child: Text(
                'No previous chats yet.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final session = history[index];
              return ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
                title: Text(
                  session.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${session.messages.where((m) => m.isUser).length} prompts',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white38),
                  onPressed: () {
                    provider.deleteChat(session.id);
                  },
                ),
                onTap: () {
                  provider.switchChat(session.id);
                  Navigator.pop(context); // Go back to the Chat Page
                },
              );
            },
          );
        },
      ),
    );
  }
}

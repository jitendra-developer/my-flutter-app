import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/chat_provider.dart';
import 'package:provider/provider.dart';

class PrePromptsPage extends StatelessWidget {
  const PrePromptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // A curated list of pre-prompts for AI interactions, focusing on image gen/modification.
    final List<Map<String, String>> prompts = [
      {
        'title': 'Generate: Cyperpunk City',
        'prompt': 'Generate a highly detailed futuristic cyberpunk city at night with neon lights, flying cars, and rain-slicked streets. 8k resolution.'
      },
      {
        'title': 'Generate: Watercolor Landscape',
        'prompt': 'Generate a serene mountain landscape in a soft watercolor painting style, with a calm lake in the foreground reflecting the pastel sky.'
      },
      {
        'title': 'Modify: Make it 3D',
        'prompt': 'Take the attached image and transform it into a vibrant 3D Pixar-style cartoon render, keeping the core subjects the same.'
      },
      {
        'title': 'Modify: Change Background to Space',
        'prompt': 'Remove the existing background from the attached image and replace it with a stunning cosmic galaxy scene featuring nebulas and stars.'
      },
      {
        'title': 'Analyze Image Detail',
        'prompt': 'Analyze this attached image. Describe all the main elements, the overall color palette, and the mood or artistic style it conveys.'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'Pre Prompts',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          final title = prompts[index]['title']!;
          final prompt = prompts[index]['prompt']!;
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  prompt,
                  style: const TextStyle(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showPromptDialog(context, title, prompt),
                child: const Text('Use'),
              ),
              onTap: () => _showPromptDialog(context, title, prompt),
            ),
          );
        },
      ),
    );
  }

  void _showPromptDialog(BuildContext context, String title, String prompt) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              prompt,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close PrePromptsPage
                
                // Reset chat state and send message
                chatProvider.createNewChat();
                chatProvider.sendMessage(prompt);
              },
              child: const Text('Start Chat'),
            ),
          ],
        );
      },
    );
  }
}

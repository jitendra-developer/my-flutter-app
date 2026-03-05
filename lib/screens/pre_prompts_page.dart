import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:myapp/chat_provider.dart';
import 'package:provider/provider.dart';

class PrePromptsPage extends StatefulWidget {
  const PrePromptsPage({super.key});

  @override
  State<PrePromptsPage> createState() => _PrePromptsPageState();
}

class _PrePromptsPageState extends State<PrePromptsPage> {
  String _selectedCategory = 'Discover';
  String _selectedSort = 'Trending'; // Add sort criteria

  final List<String> _categories = [
    'Discover',
    'Animated',
    'Realistic',
    'Cyberpunk',
    'Portraits',
    'Cinematic',
  ];

  final List<String> _sortOptions = [
    'Trending',
    'Popular',
    'Latest',
    'Relevant',
  ];

  // Mock data with images and categories for Masonry
  final List<Map<String, dynamic>> _allPrompts = [
    {
      'title': 'Professional Studio Headshot',
      'prompt':
          'A high-end professional corporate headshot of a person looking directly at the camera. Clean, neutral dark grey seamless paper background. Rembrandt lighting setup casting a soft triangle of light on the cheek. The subject wears sharp, formal business attire, a dark tailored suit. 85mm portrait lens, shallow depth of field, hyper-realistic, highly detailed skin texture.',
      'image':
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=600&auto=format&fit=crop',
      'category': 'Portraits',
    },
    {
      'title': 'Neon City Cyberpunk Edit',
      'prompt':
          'A gritty, futuristic cyberpunk portrait. Vivid neon pink and cyan rim lighting illuminating the subject\'s face and shoulders in the dark. In the background, a heavily blurred, rainy, futuristic neon city street with glowing Asian characters and holographic signs. 8k resolution, cinematic lighting, conceptual art.',
      'image':
          'https://images.unsplash.com/photo-1542362567-b07e54358753?q=80&w=600&auto=format&fit=crop',
      'category': 'Cyberpunk',
    },
    {
      'title': '3D Pixar-Style Avatar',
      'prompt':
          'A highly detailed 3D cartoon portrait of a person in the style of a modern Pixar or Disney CGI animated movie. Soft, warm, magical studio lighting. The character has large, expressive eyes, smooth stylized proportions, soft skin, and highly distinct realistic textured hair. Masterpiece, unreal engine 5 render, volumetric lighting.',
      'image':
          'https://images.unsplash.com/photo-1498334906313-6e099a1bd28d?q=80&w=600&auto=format&fit=crop',
      'category': 'Animated',
    },
    {
      'title': 'Moody Cinematic Film Look',
      'prompt':
          'A moody, cinematic still frame inspired by Christopher Nolan films. Teal and orange complementary color grading. Lifted black levels for a vintage film-like matte finish. Emphasized deep shadows, dramatic lighting from a single light source out of frame, subtle anamorphic lens flare, raw photo, 35mm film grain.',
      'image':
          'https://images.unsplash.com/photo-1535295972055-1c762f4483e5?q=80&w=600&auto=format&fit=crop',
      'category': 'Cinematic',
    },
    {
      'title': 'Hyper-Realistic Nature Profile',
      'prompt':
          'A hyper-realistic close-up portrait of a person outdoors. Extremely sharp focus on the eye specular highlights and skin pores. Beautiful natural sunlight. In the background, a naturally blurred green forest with a gorgeous, buttery shallow depth of field bokeh. Shot on Sony A7R IV, 50mm f/1.2.',
      'image':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop',
      'category': 'Realistic',
    },
    {
      'title': 'Anime Style Transformation',
      'prompt':
          'An illustration of a person in the style of a high-budget 1990s Japanese anime film. Vibrant flat cel-shaded colors, dramatic deep crisp shadows, delicate line art. Dynamic composition with stylized atmospheric background details. Makoto Shinkai style, masterwork, 4k anime wallpaper.',
      'image':
          'https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=600&auto=format&fit=crop',
      'category': 'Animated',
    },
    {
      'title': 'Dystopian Sci-Fi Scene',
      'prompt':
          'A dystopian sci-fi portrait. The subject wears dark, tactical futuristic clothing. Deep in the background, towering brutalist skyscrapers, flying vehicles, and floating holographic advertisements in a smoggy, grim mechanical atmosphere. Cinematic framing, dystopian concept art, highly detailed.',
      'image':
          'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?q=80&w=600&auto=format&fit=crop',
      'category': 'Cyberpunk',
    },
    {
      'title': '1970s Vintage Film Camera',
      'prompt':
          'An authentic 1970s vintage film photograph shot on Kodachrome. Heavy film grain, warm nostalgic color shifts with emphasized reds and yellows. Subtly underexposed with a light leak burning the left edge of the frame. Retro aesthetic, nostalgic memory vibe.',
      'image':
          'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?q=80&w=600&auto=format&fit=crop',
      'category': 'Cinematic',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter prompts based on selected category
    final filteredPrompts = _selectedCategory == 'Discover'
        ? _allPrompts
        : _allPrompts.where((p) => p['category'] == _selectedCategory).toList();

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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, color: Colors.white),
            color: const Color(0xFF2C2C2C),
            onSelected: (String result) {
              setState(() {
                _selectedSort = result;
              });
              // Currently visual/metadata only - could actually sort the list here based on fields
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sorted by $result'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.deepPurple,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            itemBuilder: (BuildContext context) => _sortOptions
                .map(
                  (String choice) => PopupMenuItem<String>(
                    value: choice,
                    child: Row(
                      children: [
                        Icon(
                          _selectedSort == choice
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _selectedSort == choice
                              ? Colors.deepPurpleAccent
                              : Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          choice,
                          style: TextStyle(
                            color: _selectedSort == choice
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of quick filters/categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple,
                    backgroundColor: const Color(0xFF2C2C2C),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Masonry Grid View for Images
          Expanded(
            child: filteredPrompts.isEmpty
                ? const Center(
                    child: Text(
                      'No prompts found for this category.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredPrompts.length,
                    itemBuilder: (context, index) {
                      final promptData = filteredPrompts[index];
                      final image = promptData['image'] as String;

                      return GestureDetector(
                        onTap: () {
                          // When tapping a prompt, we want the slider to only contain related (same category) prompts.
                          final relatedPrompts = _allPrompts
                              .where(
                                (p) => p['category'] == promptData['category'],
                              )
                              .toList();

                          // Find index of the tapped prompt in the related list
                          final initialIndex = relatedPrompts.indexWhere(
                            (p) => p['image'] == image,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PromptDetailsPage(
                                initialIndex: initialIndex,
                                prompts: relatedPrompts,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Hero(
                            tag: 'prompt_image_${image}_$index',
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return AspectRatio(
                                  aspectRatio: index % 2 == 0
                                      ? 0.8
                                      : 1.2, // Simulate different heights while loading
                                  child: Container(
                                    color: const Color(0xFF2C2C2C),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Container(
                                      color: const Color(0xFF2C2C2C),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white24,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Fullscreen Instagram-style Prompt Details Viewer
// ---------------------------------------------------------

class PromptDetailsPage extends StatefulWidget {
  final int initialIndex;
  final List<Map<String, dynamic>> prompts;

  const PromptDetailsPage({
    super.key,
    required this.initialIndex,
    required this.prompts,
  });

  @override
  State<PromptDetailsPage> createState() => _PromptDetailsPageState();
}

class _PromptDetailsPageState extends State<PromptDetailsPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Horizontal PageView for swiping between images/prompts
          PageView.builder(
            controller: _pageController,
            itemCount: widget.prompts.length,
            itemBuilder: (context, index) {
              final promptData = widget.prompts[index];
              final image = promptData['image'] as String;
              final title = promptData['title'] as String;
              final promptText = promptData['prompt'] as String;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full Image Background
                  Hero(
                    tag: 'prompt_image_${image}_$index',
                    child: Image.network(
                      image,
                      fit: BoxFit
                          .contain, // Maintain aspect ratio in full screen
                    ),
                  ),

                  // Gradient Overlay specifically for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 80,
                        bottom: 40,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.9),
                            Colors.black,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Previous/Next hints (Instagram style dots or arrows can go here, but swiping is intuitive)

                          // Title Overlay
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Prompt Text Overlay
                          Text(
                            promptText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Action Row
                          Row(
                            children: [
                              // Copy Button
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white54,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: promptText),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Prompt copied to clipboard!',
                                        ),
                                        backgroundColor: Colors.deepPurple,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const FaIcon(
                                    FontAwesomeIcons.copy,
                                    size: 16,
                                  ),
                                  label: const Text('Copy Prompt'),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Share Button (Visual only)
                              IconButton(
                                onPressed: () {
                                  // Share functionality (non-functional per requirements)
                                },
                                icon: const Icon(
                                  Icons.send_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Top App Bar Layer (Transparent)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // Side navigation arrows hint (Optional but requested for next/prev feel)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white54,
                size: 36,
              ),
              onPressed: () {
                if (_pageController.page!.round() > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.white54,
                size: 36,
              ),
              onPressed: () {
                if (_pageController.page!.round() < widget.prompts.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

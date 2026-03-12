import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
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
  String _selectedSort = 'Trending';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  // Mock data with grouped variants
  final List<Map<String, dynamic>> _allPrompts = [
    {
      'title': 'Professional Studio Headshot',
      'category': 'Portraits',
      'variants': [
        {
          'prompt': 'A high-end professional corporate headshot of a person looking directly at the camera. Clean, neutral dark grey seamless paper background. Rembrandt lighting setup casting a soft triangle of light on the cheek. The subject wears sharp, formal business attire, a dark tailored suit. 85mm portrait lens, shallow depth of field, hyper-realistic, highly detailed skin texture.',
          'image': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=600&auto=format&fit=crop',
        },
        {
          'prompt': 'A high-end professional corporate headshot of a person looking slightly away from the camera. Warm beige seamless paper background. Butterfly lighting setup producing a soft glow. The subject wears modern business casual attire. 85mm portrait lens, shallow depth of field, natural and approachable expression.',
          'image': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=600&auto=format&fit=crop',
        },
        {
          'prompt': 'A high-end professional corporate headshot with a slight smile. Soft window light coming from the left. Clean, beautifully blurred modern office environment in the background. The subject is wearing a crisp white shirt. 50mm lens, bright and optimistic corporate portrait.',
          'image': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=600&auto=format&fit=crop',
        }
      ],
    },
    {
      'title': 'Neon City Cyberpunk',
      'category': 'Cyberpunk',
      'variants': [
        {
          'prompt': 'A gritty, futuristic cyberpunk portrait. Vivid neon pink and cyan rim lighting illuminating the subject\'s face and shoulders in the dark. In the background, a heavily blurred, rainy, futuristic neon city street with glowing Asian characters and holographic signs. 8k resolution, cinematic lighting, conceptual art.',
          'image': 'https://images.unsplash.com/photo-1542362567-b07e54358753?q=80&w=600&auto=format&fit=crop',
        },
        {
          'prompt': 'A neon-drenched cyberpunk portrait with rain hitting the subject\'s clear illuminated face shield. Acid green and deep purple lighting. Dark, dirty alleyway with glowing neon tubes and wires hanging in the background. Masterpiece, highly detailed.',
          'image': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=600&auto=format&fit=crop',
        },
      ],
    },
    {
      'title': '3D Pixar-Style Avatar',
      'category': 'Animated',
      'variants': [
        {
          'prompt': 'A highly detailed 3D cartoon portrait of a person in the style of a modern Pixar or Disney CGI animated movie. Soft, warm, magical studio lighting. The character has large, expressive eyes, smooth stylized proportions, soft skin, and highly distinct realistic textured hair. Masterpiece, unreal engine 5 render, volumetric lighting.',
          'image': 'https://images.unsplash.com/photo-1498334906313-6e099a1bd28d?q=80&w=600&auto=format&fit=crop',
        },
        {
          'prompt': 'A 3D cartoon portrait of a person in modern Pixar style, stylized proportions. Holding a magical glowing orb. Cold, magical cyan light bouncing off their face. Large expressive eyes, incredibly detailed Pixar skin shading. Unreal engine 5 render, beautiful cinematic rim lighting.',
          'image': 'https://images.unsplash.com/photo-1514755106263-5df3f317b3d3?q=80&w=600&auto=format&fit=crop',
        },
      ],
    },
    {
      'title': 'Moody Cinematic Film Look',
      'category': 'Cinematic',
      'variants': [
        {
          'prompt': 'A moody, cinematic still frame inspired by Christopher Nolan films. Teal and orange complementary color grading. Lifted black levels for a vintage film-like matte finish. Emphasized deep shadows, dramatic lighting from a single light source out of frame, subtle anamorphic lens flare, raw photo, 35mm film grain.',
          'image': 'https://images.unsplash.com/photo-1535295972055-1c762f4483e5?q=80&w=600&auto=format&fit=crop',
        },
        {
          'prompt': 'Cinematic medium shot of a person looking out of a rain-streaked window at night. Low key lighting, high contrast. A glowing streetlamp casting warm golden light over their profile against deep blue shadows. 35mm lens, movie still frame, Kodak Vision3 500T film stock.',
          'image': 'https://images.unsplash.com/photo-1533038590840-1c793ba64524?q=80&w=600&auto=format&fit=crop',
        },
      ],
    },
    {
      'title': 'Hyper-Realistic Nature Profile',
      'category': 'Realistic',
      'variants': [
        {
          'prompt': 'A hyper-realistic close-up portrait of a person outdoors. Extremely sharp focus on the eye specular highlights and skin pores. Beautiful natural sunlight. In the background, a naturally blurred green forest with a gorgeous, buttery shallow depth of field bokeh. Shot on Sony A7R IV, 50mm f/1.2.',
          'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop',
        },
        {
          'prompt': 'A hyper-realistic close-up portrait outdoors during golden hour. Warm back-lighting from a low sun casting a halo effect on the subject\'s hair. Perfectly sharp eye details. Blurred open field background with warm sunset colors. Shot on Canon EOS R5, 85mm f/1.2 L.',
          'image': 'https://images.unsplash.com/photo-1479936343636-73cdc5aae0c3?q=80&w=600&auto=format&fit=crop',
        },
      ],
    },
    {
      'title': 'Anime Style Transformation',
      'category': 'Animated',
      'variants': [
        {
          'prompt': 'An illustration of a person in the style of a high-budget 1990s Japanese anime film. Vibrant flat cel-shaded colors, dramatic deep crisp shadows, delicate line art. Dynamic composition with stylized atmospheric background details. Makoto Shinkai style, masterwork, 4k anime wallpaper.',
          'image': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=600&auto=format&fit=crop',
        },
        {
          'prompt': 'An illustration of a person in the style of Studio Ghibli. Soft, lush watercolor backgrounds with vivid green foliage. The character outline is slightly textured and organic. Warm, nostalgic summer afternoon lighting, peaceful atmosphere, masterpiece.',
          'image': 'https://images.unsplash.com/photo-1541562232579-512a21360020?q=80&w=600&auto=format&fit=crop',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Filter by category
    final categoryFiltered = _selectedCategory == 'Discover'
        ? _allPrompts
        : _allPrompts.where((p) => p['category'] == _selectedCategory).toList();

    // 2. Filter by search query
    final query = _searchController.text.toLowerCase().trim();
    final filteredPrompts = query.isEmpty
        ? categoryFiltered
        : categoryFiltered.where((p) {
            final titleUrl = (p['title'] as String).toLowerCase();
            final catStr = (p['category'] as String).toLowerCase();
            final variants = p['variants'] as List<dynamic>;
            final textStr = variants.join(' ').toLowerCase();

            return titleUrl.contains(query) ||
                   catStr.contains(query) ||
                   textStr.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search categories or prompts...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onChanged: (_) {
                  // Trigger rebuild to update search results
                  setState(() {});
                },
              )
            : Text(
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, color: Colors.white),
            color: const Color(0xFF2C2C2C),
            onSelected: (String result) {
              setState(() {
                _selectedSort = result;
              });
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
                final isDiscover = category == 'Discover';
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12.0),
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [Color(0xFF3B2E7E), Color(0xFF4A60D4)])
                          : null,
                      color: isSelected ? null : const Color(0xFF1C1C24),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? null : Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDiscover) ...[
                          const Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          category,
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected ? Colors.white : const Color(0xFF8F8F99),
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
                      'No prompts or categories found.',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
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
                      // Display the first variant on the grid
                      final variants = promptData['variants'] as List<dynamic>;
                      final image = variants[0]['image'] as String;

                      return GestureDetector(
                        onTap: () {
                          // Pass all filtered prompt groups to allow up/down swiping
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PromptDetailsPage(
                                initialPromptGroupIndex: index,
                                promptGroups: filteredPrompts,
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
                                  aspectRatio: index % 2 == 0 ? 0.8 : 1.2,
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
// Fullscreen 2D Prompt Details Viewer (Vertical & Horizontal Swiping)
// ---------------------------------------------------------

class PromptDetailsPage extends StatefulWidget {
  final int initialPromptGroupIndex;
  final List<Map<String, dynamic>> promptGroups;

  const PromptDetailsPage({
    super.key,
    required this.initialPromptGroupIndex,
    required this.promptGroups,
  });

  @override
  State<PromptDetailsPage> createState() => _PromptDetailsPageState();
}

class _PromptDetailsPageState extends State<PromptDetailsPage> {
  late PageController _verticalController;

  @override
  void initState() {
    super.initState();
    _verticalController =
        PageController(initialPage: widget.initialPromptGroupIndex);
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical PageView for swiping UP/DOWN between different prompt themes
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _verticalController,
            itemCount: widget.promptGroups.length,
            itemBuilder: (context, verticalIndex) {
              final promptData = widget.promptGroups[verticalIndex];
              final title = promptData['title'] as String;
              final variants = promptData['variants'] as List<dynamic>;

              // Every vertical page contains a horizontal PageView for its variants
              return _PromptVariantRow(
                variants: variants,
                title: title,
                verticalIndex: verticalIndex,
              );
            },
          ),

          // Top App Bar Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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


        ],
      ),
    );
  }
}

// Stateful Widget for the horizontal variants to manage their own pagination indicators
class _PromptVariantRow extends StatefulWidget {
  final List<dynamic> variants;
  final String title;
  final int verticalIndex;

  const _PromptVariantRow({
    required this.variants,
    required this.title,
    required this.verticalIndex,
  });

  @override
  State<_PromptVariantRow> createState() => _PromptVariantRowState();
}

class _PromptVariantRowState extends State<_PromptVariantRow> {
  final PageController _horizontalController = PageController();
  int _currentVariantIndex = 0;

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          scrollDirection: Axis.horizontal,
          controller: _horizontalController,
          onPageChanged: (index) {
            setState(() {
              _currentVariantIndex = index;
            });
          },
          itemCount: widget.variants.length,
          itemBuilder: (context, horizontalIndex) {
            final variant = widget.variants[horizontalIndex];
            final image = variant['image'] as String;
            final promptText = variant['prompt'] as String;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Full Image Background
                Hero(
                  tag: 'prompt_image_${image}_${widget.verticalIndex}',
                  child: Image.network(
                    image,
                    fit: BoxFit.cover, 
                  ),
                ),

                // Gradient Overlay
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
                        // Title Overlay
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Prompt Text
                        Text(
                          promptText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Variant Indicators (Dots)
                        if (widget.variants.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.variants.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentVariantIndex == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentVariantIndex == index
                                      ? Colors.deepPurpleAccent
                                      : Colors.white24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

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
                                        'Prompt variant copied to clipboard!',
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
                            IconButton(
                              onPressed: () {
                                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                                chatProvider.createNewChat();
                                chatProvider.sendMessage(promptText);
                                context.go('/chat');
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
        

      ],
    );
  }
}

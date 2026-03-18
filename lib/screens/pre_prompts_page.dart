import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:myapp/chat_provider.dart';
import 'package:myapp/screens/reel_player_page.dart';
import 'package:myapp/services/api_service.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

String? _youtubeId(String url) {
  final patterns = [
    RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(url);
    if (m != null) return m.group(1);
  }
  return null;
}

String? _reelThumb(Map<String, dynamic> reel) {
  final override = reel['thumbnail_url'] as String?;
  if (override != null && override.isNotEmpty) return override;
  final videoUrl = reel['video_url'] as String? ?? '';
  final id = _youtubeId(videoUrl);
  if (id != null) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  return null;
}

enum _ContentFilter { both, onlyImages, onlyVideos }

// ─────────────────────────────────────────────────────────────────────────────
//  Feed Page
// ─────────────────────────────────────────────────────────────────────────────

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String _selectedCategory = 'Discover';
  String _selectedSort = 'Trending';
  _ContentFilter _contentFilter = _ContentFilter.both;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _apiPrompts = [];
  List<Map<String, dynamic>> _apiReels = [];
  bool _promptsLoaded = false;
  bool _reelsLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchPrompts();
    _fetchReels();
  }

  Future<void> _fetchPrompts() async {
    try {
      final raw = await ApiService().getPrePrompts();
      final converted = raw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final rawVariants = map['variants'];
        if (rawVariants is List) {
          map['variants'] = rawVariants
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList();
        } else {
          map['variants'] = <Map<String, dynamic>>[];
        }
        return map;
      }).toList();
      if (mounted) setState(() { _apiPrompts = converted; _promptsLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _promptsLoaded = true);
    }
  }

  Future<void> _fetchReels() async {
    try {
      final raw = await ApiService().getReels();
      if (mounted) {
        setState(() {
          _apiReels = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _reelsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _reelsLoaded = true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _categories = [
    'Discover', 'Animated', 'Realistic', 'Cyberpunk', 'Portraits', 'Cinematic',
  ];

  final List<String> _sortOptions = ['Trending', 'Popular', 'Latest', 'Relevant'];

  // ── Filtering & sorting ────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredPrompts {
    var list = _selectedCategory == 'Discover'
        ? _apiPrompts
        : _apiPrompts.where((p) => p['category'] == _selectedCategory).toList();

    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      list = list.where((p) {
        final title = (p['title'] as String? ?? '').toLowerCase();
        final cat = (p['category'] as String? ?? '').toLowerCase();
        final variants = p['variants'] as List<dynamic>;
        final text = variants.join(' ').toLowerCase();
        return title.contains(query) || cat.contains(query) || text.contains(query);
      }).toList();
    }
    return _sortedList(list);
  }

  List<Map<String, dynamic>> get _filteredReels {
    var list = _apiReels;
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      list = list.where((r) {
        final title = (r['title'] as String? ?? '').toLowerCase();
        final desc = (r['description'] as String? ?? '').toLowerCase();
        return title.contains(query) || desc.contains(query);
      }).toList();
    }
    return _sortedList(list);
  }

  List<Map<String, dynamic>> _sortedList(List<Map<String, dynamic>> src) {
    final list = List<Map<String, dynamic>>.from(src);
    switch (_selectedSort) {
      case 'Trending':
      case 'Popular':
        list.sort((a, b) =>
            ((b['likes_count'] as int? ?? 0)).compareTo((a['likes_count'] as int? ?? 0)));
      case 'Latest':
        list.sort((a, b) =>
            (b['created_at'] as String? ?? '').compareTo(a['created_at'] as String? ?? ''));
    }
    return list;
  }

  // Unified feed: interleave prompts + reels based on content filter
  List<Map<String, dynamic>> get _feedItems {
    final prompts = _filteredPrompts;
    final reels = _filteredReels;

    switch (_contentFilter) {
      case _ContentFilter.onlyImages:
        return prompts.map((p) { final m = Map<String, dynamic>.from(p); m['__isReel'] = false; return m; }).toList();
      case _ContentFilter.onlyVideos:
        return reels.map((r) { final m = Map<String, dynamic>.from(r); m['__isReel'] = true; return m; }).toList();
      case _ContentFilter.both:
        if (reels.isEmpty) {
          return prompts.map((p) { final m = Map<String, dynamic>.from(p); m['__isReel'] = false; return m; }).toList();
        }
        if (prompts.isEmpty) {
          return reels.map((r) { final m = Map<String, dynamic>.from(r); m['__isReel'] = true; return m; }).toList();
        }
        // Distribute reels evenly among prompts
        final result = <Map<String, dynamic>>[];
        final interval = (prompts.length / reels.length).ceil().clamp(1, 6);
        int reelIdx = 0;
        for (int i = 0; i < prompts.length; i++) {
          final p = Map<String, dynamic>.from(prompts[i]);
          p['__isReel'] = false;
          result.add(p);
          if ((i + 1) % interval == 0 && reelIdx < reels.length) {
            final r = Map<String, dynamic>.from(reels[reelIdx++]);
            r['__isReel'] = true;
            result.add(r);
          }
        }
        while (reelIdx < reels.length) {
          final r = Map<String, dynamic>.from(reels[reelIdx++]);
          r['__isReel'] = true;
          result.add(r);
        }
        return result;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoaded = _promptsLoaded && _reelsLoaded;
    final items = _feedItems;

    // Sublists for context-aware tap navigation
    final promptGroups = items
        .where((i) => !(i['__isReel'] as bool))
        .map((p) { final m = Map<String, dynamic>.from(p); m.remove('__isReel'); return m; })
        .toList();
    final reelsList = items
        .where((i) => i['__isReel'] as bool)
        .map((r) { final m = Map<String, dynamic>.from(r); m.remove('__isReel'); return m; })
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search feed...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(
                'Feed',
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
              setState(() { _isSearching = false; _searchController.clear(); });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => setState(() => _isSearching = true),
            ),
          _buildFilterMenu(context),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12.0),
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF3B2E7E), Color(0xFF4A60D4)])
                          : null,
                      color: isSelected ? null : const Color(0xFF1C1C24),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? null : Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (category == 'Discover') ...[
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

          // Masonry grid
          Expanded(
            child: !isLoaded
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A60D4)))
                : items.isEmpty
                    ? const Center(
                        child: Text(
                          'Nothing to show.',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() { _promptsLoaded = false; _reelsLoaded = false; });
                          await Future.wait([_fetchPrompts(), _fetchReels()]);
                        },
                        color: const Color(0xFF4A60D4),
                        child: MasonryGridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isReel = item['__isReel'] as bool;

                            if (isReel) {
                              return _ReelTile(
                                reel: item,
                                tileIndex: index,
                                onTap: () async {
                                  final reelId = item['id'];
                                  final reelIndex = reelsList
                                      .indexWhere((r) => r['id'] == reelId);
                                  final result = await Navigator.push<List<Map<String, dynamic>>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReelPlayerPage(
                                        reels: reelsList,
                                        initialIndex: reelIndex >= 0 ? reelIndex : 0,
                                      ),
                                    ),
                                  );
                                  if (result != null && mounted) {
                                    setState(() {
                                      for (final updated in result) {
                                        final idx = _apiReels
                                            .indexWhere((r) => r['id'] == updated['id']);
                                        if (idx >= 0) _apiReels[idx] = updated;
                                      }
                                    });
                                  }
                                },
                              );
                            } else {
                              final variants = item['variants'] as List<dynamic>;
                              if (variants.isEmpty) return const SizedBox.shrink();
                              final image = variants[0]['image']?.toString() ?? '';
                              final itemId = item['id'];
                              final promptIndex =
                                  promptGroups.indexWhere((p) => p['id'] == itemId);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PromptDetailsPage(
                                        initialPromptGroupIndex:
                                            promptIndex >= 0 ? promptIndex : 0,
                                        promptGroups: promptGroups,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Hero(
                                    tag: 'prompt_image_${image}_${promptIndex >= 0 ? promptIndex : index}',
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
                                                  color: Colors.deepPurple),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, _, _) => AspectRatio(
                                        aspectRatio: 1.0,
                                        child: Container(
                                          color: const Color(0xFF2C2C2C),
                                          child: const Icon(Icons.image_not_supported,
                                              color: Colors.white24, size: 50),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMenu(BuildContext context) {
    final isFiltered = _contentFilter != _ContentFilter.both;
    return PopupMenuButton<String>(
      icon: Icon(Icons.tune, color: isFiltered ? const Color(0xFF4A60D4) : Colors.white),
      color: const Color(0xFF2C2C2C),
      onSelected: (result) {
        setState(() {
          switch (result) {
            case 'Only Images': _contentFilter = _ContentFilter.onlyImages;
            case 'Only Videos': _contentFilter = _ContentFilter.onlyVideos;
            case 'Both':        _contentFilter = _ContentFilter.both;
            default:            _selectedSort = result;
          }
        });
        final isContentFilter = ['Only Images', 'Only Videos', 'Both'].contains(result);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isContentFilter ? 'Showing $result' : 'Sorted by $result'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
          duration: const Duration(seconds: 1),
        ));
      },
      itemBuilder: (_) => [
        const PopupMenuItem<String>(
          enabled: false,
          height: 28,
          child: Text('Sort by', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        ..._sortOptions.map((choice) => PopupMenuItem<String>(
          value: choice,
          child: Row(children: [
            Icon(
              _selectedSort == choice ? Icons.radio_button_checked : Icons.radio_button_off,
              color: _selectedSort == choice ? Colors.deepPurpleAccent : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(choice,
                style: TextStyle(
                    color: _selectedSort == choice ? Colors.white : Colors.white70)),
          ]),
        )),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          enabled: false,
          height: 28,
          child: Text('Show', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        ...['Both', 'Only Images', 'Only Videos'].map((label) {
          final isActive = (label == 'Both' && _contentFilter == _ContentFilter.both) ||
              (label == 'Only Images' && _contentFilter == _ContentFilter.onlyImages) ||
              (label == 'Only Videos' && _contentFilter == _ContentFilter.onlyVideos);
          return PopupMenuItem<String>(
            value: label,
            child: Row(children: [
              Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isActive ? Colors.deepPurpleAccent : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(color: isActive ? Colors.white : Colors.white70)),
            ]),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reel tile (in masonry grid)
// ─────────────────────────────────────────────────────────────────────────────

class _ReelTile extends StatelessWidget {
  final Map<String, dynamic> reel;
  final int tileIndex;
  final VoidCallback onTap;

  const _ReelTile({required this.reel, required this.tileIndex, required this.onTap});

  double get _height {
    const heights = [200.0, 260.0, 220.0, 180.0, 250.0, 210.0];
    return heights[tileIndex % heights.length];
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _reelThumb(reel);
    final title = reel['title'] as String? ?? '';
    final isSaved = reel['is_saved'] as bool? ?? false;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: _height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail or gradient placeholder
              if (thumb != null)
                Image.network(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _GradientThumb(),
                )
              else
                const _GradientThumb(),

              // Gradient scrim
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),

              // Play icon
              const Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),

              // Saved indicator
              if (isSaved)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A60D4).withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark, color: Colors.white, size: 12),
                  ),
                ),

              // Title at bottom
              if (title.isNotEmpty)
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientThumb extends StatelessWidget {
  const _GradientThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C2C3E), Color(0xFF3B2E7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Prompt details page (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

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
    _verticalController = PageController(initialPage: widget.initialPromptGroupIndex);
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
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _verticalController,
            itemCount: widget.promptGroups.length,
            itemBuilder: (context, verticalIndex) {
              final promptData = widget.promptGroups[verticalIndex];
              final title = promptData['title'] as String;
              final variants = promptData['variants'] as List<dynamic>;
              return _PromptVariantRow(
                variants: variants,
                title: title,
                verticalIndex: verticalIndex,
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
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
          onPageChanged: (index) => setState(() => _currentVariantIndex = index),
          itemCount: widget.variants.length,
          itemBuilder: (context, horizontalIndex) {
            final variant = widget.variants[horizontalIndex];
            final image = variant['image'] as String;
            final promptText = variant['prompt'] as String;

            return Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'prompt_image_${image}_${widget.verticalIndex}',
                  child: Image.network(image, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 80, bottom: 40, left: 16, right: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.9),
                          Colors.black,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Text(
                          promptText,
                          style: const TextStyle(
                            color: Colors.white70, fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 24),
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
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: promptText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Prompt variant copied to clipboard!'),
                                      backgroundColor: Colors.deepPurple,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const FaIcon(FontAwesomeIcons.copy, size: 16),
                                label: const Text('Copy Prompt'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                final chatProvider = Provider.of<ChatProvider>(
                                    context, listen: false);
                                chatProvider.createNewChat();
                                chatProvider.sendMessage(promptText);
                                context.go('/chat');
                              },
                              icon: const Icon(Icons.send_outlined,
                                  color: Colors.white, size: 28),
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

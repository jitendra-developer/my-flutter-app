import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:myapp/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Extracts the YouTube video ID from any common YouTube URL format.
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

/// Returns the best available thumbnail URL for a video URL.
String? _thumbUrl(Map<String, dynamic> video) {
  final override = video['thumbnail_url'] as String?;
  if (override != null && override.isNotEmpty) return override;
  final videoUrl = video['video_url'] as String? ?? '';
  final id = _youtubeId(videoUrl);
  if (id != null) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Learn Page
// ─────────────────────────────────────────────────────────────────────────────

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _videos = [];
  // null = still loading (shows skeletons), false/true = done
  bool _loaded = false;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Fallback videos ────────────────────────────────────────────────────────
  // Shown only if the API returns an empty list or fails.
  // Replace these with real video URLs once you have them.
  static const List<Map<String, dynamic>> _fallback = [
    {
      'id': 1,
      'title': 'Getting Started with Vakya Pro',
      'description': 'A quick intro to the app — chat, voice mode, and more.',
      'category': 'Basics',
      'video_url': '',
      'thumbnail_url': null,
      'duration': '3:12',
    },
    {
      'id': 2,
      'title': 'How to Use Voice Mode',
      'description': 'Hands-free AI conversations using continuous voice mode.',
      'category': 'Voice',
      'video_url': '',
      'thumbnail_url': null,
      'duration': '4:45',
    },
    {
      'id': 3,
      'title': 'Writing Better Prompts',
      'description': 'Tips for getting the best responses from the AI.',
      'category': 'Tips',
      'video_url': '',
      'thumbnail_url': null,
      'duration': '5:20',
    },
    {
      'id': 4,
      'title': 'Changing Language Settings',
      'description': 'Switch the app and AI language in seconds.',
      'category': 'Settings',
      'video_url': '',
      'thumbnail_url': null,
      'duration': '2:05',
    },
    {
      'id': 5,
      'title': 'Managing Your Profile',
      'description': 'Update name, avatar, and password from the profile page.',
      'category': 'Settings',
      'video_url': '',
      'thumbnail_url': null,
      'duration': '3:30',
    },
    {
      'id': 6,
      'title': 'Image Generation Tips',
      'description': 'Get stunning AI images with the right prompt keywords.',
      'category': 'Tips',
      'video_url': '',
      'thumbnail_url': null,
      'duration': '6:15',
    },
  ];

  final List<String> _categories = [
    'All',
    'Basics',
    'Voice',
    'Tips',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    // Show skeletons while fetching
    try {
      final raw = await ApiService().getLearnArticles();
      if (mounted) {
        final fetched = raw
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        setState(() {
          _videos = fetched.isNotEmpty ? fetched : List.from(_fallback);
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _videos = List.from(_fallback);
          _loaded = true;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _selectedCategory == 'All'
        ? _videos
        : _videos.where((v) => v['category'] == _selectedCategory).toList();
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((v) {
      final title = (v['title'] as String? ?? '').toLowerCase();
      final desc = (v['description'] as String? ?? '').toLowerCase();
      return title.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Learn',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search videos, #hashtags...',
                hintStyle:
                    GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white38, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF2C2C3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ── Category chips ───────────────────────────────────────────────
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4A60D4)
                          : const Color(0xFF2C2C3E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.poppins(
                        color:
                            isSelected ? Colors.white : Colors.white60,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Video list ───────────────────────────────────────────────────
          Expanded(
            child: !_loaded
                ? _SkeletonList()
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No videos in this category yet.',
                          style: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, i) => _VideoCard(
                          video: _filtered[i],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Video Card
// ─────────────────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  const _VideoCard({required this.video});

  Future<void> _open(BuildContext context) async {
    final rawUrl = video['video_url'] as String? ?? '';
    if (rawUrl.isEmpty) return;
    final title = video['title'] as String? ?? 'Untitled';
    // Play YouTube videos in-app
    if (_youtubeId(rawUrl) != null) {
      final videoId = video['id']?.toString() ?? '';
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _LearnVideoPlayerPage(
              videoId: videoId, videoUrl: rawUrl, title: title),
        ),
      );
      return;
    }
    // Fallback: open other URLs externally
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _thumbUrl(video);
    final title = video['title'] as String? ?? 'Untitled';
    final desc = video['description'] as String? ?? '';
    final category = video['category'] as String? ?? '';
    final duration = video['duration'] as String? ?? '';
    final hasUrl = (video['video_url'] as String? ?? '').isNotEmpty;

    return GestureDetector(
      onTap: hasUrl ? () => _open(context) : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Actual thumbnail or gradient placeholder
                    if (thumb != null)
                      Image.network(
                        thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _GradientThumb(),
                      )
                    else
                      const _GradientThumb(),

                    // Play button overlay
                    if (hasUrl)
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 34),
                        ),
                      ),

                    // Duration badge (bottom-right)
                    if (duration.isNotEmpty)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            duration,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  if (category.isNotEmpty) _CategoryChip(label: category),
                  if (category.isNotEmpty) const SizedBox(height: 6),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // "Coming soon" if no URL
                  if (!hasUrl) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Coming soon',
                      style: GoogleFonts.poppins(
                        color: Colors.white30,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  In-App Video Player for Learn page
// ─────────────────────────────────────────────────────────────────────────────

class _LearnVideoPlayerPage extends StatefulWidget {
  final String videoId;
  final String videoUrl;
  final String title;

  const _LearnVideoPlayerPage(
      {required this.videoId, required this.videoUrl, required this.title});

  @override
  State<_LearnVideoPlayerPage> createState() => _LearnVideoPlayerPageState();
}

class _LearnVideoPlayerPageState extends State<_LearnVideoPlayerPage> {
  final _api = ApiService();
  VideoPlayerController? _videoCtrl;
  YoutubePlayerController? _ytCtrl;
  bool _isYT = false;
  bool _initialized = false;
  bool _isPlaying = true;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _isYT = _youtubeId(widget.videoUrl) != null;
    _init();
  }

  Future<void> _init() async {
    if (_isYT) {
      final id = _youtubeId(widget.videoUrl)!;
      _ytCtrl = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          loop: false,
          hideControls: false,
          controlsVisibleAtStart: true,
        ),
      );
      if (mounted) setState(() => _initialized = true);
    } else {
      try {
        final ctrl =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        await ctrl.initialize();
        ctrl.play();
        _videoCtrl = ctrl;
        if (mounted) setState(() => _initialized = true);
      } catch (_) {}
    }
  }

  void _togglePlayPause() {
    if (_isYT && _ytCtrl != null) {
      if (_isPlaying) {
        _ytCtrl!.pause();
      } else {
        _ytCtrl!.play();
      }
    } else if (_videoCtrl != null) {
      if (_videoCtrl!.value.isPlaying) {
        _videoCtrl!.pause();
      } else {
        _videoCtrl!.play();
      }
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _sendView();
    _videoCtrl?.dispose();
    _ytCtrl?.dispose();
    super.dispose();
  }

  void _sendView() {
    if (widget.videoId.isEmpty) return;
    final ms = DateTime.now().difference(_startedAt).inMilliseconds;
    if (ms <= 0) return;
    final completed = _videoCtrl != null
        ? (_videoCtrl!.value.position >= _videoCtrl!.value.duration &&
            _videoCtrl!.value.duration.inMilliseconds > 0)
        : false;
    _api.recordLearnView(widget.videoId, ms, isCompleted: completed)
        .catchError((_) => <String, dynamic>{});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Player area ──────────────────────────────────────────────
            Center(
              child: !_initialized
                  ? const CircularProgressIndicator(
                      color: Colors.white54, strokeWidth: 2)
                  : _isYT && _ytCtrl != null
                      ? YoutubePlayer(
                          controller: _ytCtrl!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor:
                              const Color(0xFF4A60D4),
                        )
                      : _videoCtrl != null
                          ? GestureDetector(
                              onTap: _togglePlayPause,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio:
                                        _videoCtrl!.value.aspectRatio,
                                    child: VideoPlayer(_videoCtrl!),
                                  ),
                                  if (!_videoCtrl!.value.isPlaying)
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 40),
                                    ),
                                ],
                              ),
                            )
                          : const SizedBox(),
            ),

            // ── Back button ──────────────────────────────────────────────
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 22),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // ── Title at bottom ──────────────────────────────────────────
            Positioned(
              left: 14,
              right: 14,
              bottom: 16,
              child: Text(
                widget.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Gradient placeholder thumbnail
// ─────────────────────────────────────────────────────────────────────────────

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
      child: const Center(
        child: Icon(Icons.play_circle_outline_rounded,
            size: 56, color: Colors.white24),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category chip badge
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4A60D4).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF4A60D4).withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: const Color(0xFF4A60D4),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton loader — shown while API request is in flight
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonList extends StatefulWidget {
  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final opacity = 0.35 + 0.35 * _anim.value; // pulses 0.35 → 0.70
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, _) => _SkeletonCard(opacity: opacity),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double opacity;
  const _SkeletonCard({required this.opacity});

  Widget _box({double? w, double h = 14, double radius = 8}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A4A),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton (16:9)
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Opacity(
              opacity: opacity,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(color: const Color(0xFF2C2C3E)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(w: 70, h: 20, radius: 12), // category chip
                const SizedBox(height: 8),
                _box(w: double.infinity, h: 15), // title line 1
                const SizedBox(height: 6),
                _box(w: 200, h: 15), // title line 2
                const SizedBox(height: 8),
                _box(w: double.infinity, h: 12), // desc line
                const SizedBox(height: 4),
                _box(w: 140, h: 12), // desc line 2
              ],
            ),
          ),
        ],
      ),
    );
  }
}

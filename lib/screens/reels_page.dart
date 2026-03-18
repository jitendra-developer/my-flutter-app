import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/screens/reel_player_page.dart';
import 'package:myapp/services/api_service.dart';

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

String? _thumbUrl(Map<String, dynamic> reel) {
  final override = reel['thumbnail_url'] as String?;
  if (override != null && override.isNotEmpty) return override;
  final videoUrl = reel['video_url'] as String? ?? '';
  final id = _youtubeId(videoUrl);
  if (id != null) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  return null;
}

// Alternating heights for masonry effect
double _tileHeight(int index) {
  const heights = [200.0, 260.0, 220.0, 180.0, 250.0, 210.0];
  return heights[index % heights.length];
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reels Page  (grid view entry point)
// ─────────────────────────────────────────────────────────────────────────────

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final _api = ApiService();

  List<Map<String, dynamic>> _reels = [];
  bool _loaded = false;
  String? _error;
  bool _showSaved = false;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    setState(() {
      _loaded = false;
      _error = null;
    });
    try {
      final data = await _api.getReels();
      if (mounted) {
        setState(() {
          _reels =
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loaded = true;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _savedReels =>
      _reels.where((r) => r['is_saved'] as bool? ?? false).toList();

  List<Map<String, dynamic>> get _filteredReels {
    final source = _showSaved ? _savedReels : _reels;
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source.where((r) {
      final title = (r['title'] as String? ?? '').toLowerCase();
      final desc = (r['description'] as String? ?? '').toLowerCase();
      return title.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPlayer(int globalIndex) async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => ReelPlayerPage(
          reels: _reels,
          initialIndex: globalIndex,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _reels = result);
    }
  }

  Future<void> _openPlayerFromSaved(Map<String, dynamic> reel) async {
    final globalIndex = _reels.indexWhere((r) => r['id'] == reel['id']);
    if (globalIndex >= 0) await _openPlayer(globalIndex);
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
          _showSaved ? 'Saved Reels' : 'AI Reels',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar + saved toggle ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search reels, #hashtags...',
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.white38, size: 20),
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
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _showSaved
                        ? const Color(0xFF4A60D4)
                        : const Color(0xFF2C2C3E),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                    ),
                    tooltip:
                        _showSaved ? 'Back to All Reels' : 'Saved Reels',
                    onPressed: () {
                      setState(() {
                        _showSaved = !_showSaved;
                        _searchCtrl.clear();
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: !_loaded
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF4A60D4)))
                : _error != null
                    ? _ErrorState(onRetry: _loadReels)
                    : _showSaved
                        ? _savedReels.isEmpty
                            ? _EmptySavedState(
                                onBrowse: () =>
                                    setState(() => _showSaved = false))
                            : _filteredReels.isEmpty
                                ? _NoSearchResults(
                                    onClear: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : _ReelGrid(
                                    reels: _filteredReels,
                                    onTap: _openPlayerFromSaved,
                                  )
                        : _reels.isEmpty
                            ? const _EmptyState()
                            : _filteredReels.isEmpty
                                ? _NoSearchResults(
                                    onClear: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadReels,
                                    color: const Color(0xFF4A60D4),
                                    child: _ReelGrid(
                                      reels: _filteredReels,
                                      onTap: (reel) {
                                        final idx = _reels.indexOf(reel);
                                        if (idx >= 0) _openPlayer(idx);
                                      },
                                    ),
                                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Masonry Grid
// ─────────────────────────────────────────────────────────────────────────────

class _ReelGrid extends StatelessWidget {
  final List<Map<String, dynamic>> reels;
  final void Function(Map<String, dynamic> reel) onTap;

  const _ReelGrid({required this.reels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      padding: const EdgeInsets.all(3),
      itemCount: reels.length,
      itemBuilder: (context, index) {
        final reel = reels[index];
        return GestureDetector(
          onTap: () => onTap(reel),
          child: _ReelThumbnail(
            reel: reel,
            height: _tileHeight(index),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Thumbnail tile
// ─────────────────────────────────────────────────────────────────────────────

class _ReelThumbnail extends StatelessWidget {
  final Map<String, dynamic> reel;
  final double height;

  const _ReelThumbnail({required this.reel, required this.height});

  @override
  Widget build(BuildContext context) {
    final thumb = _thumbUrl(reel);
    final title = reel['title'] as String? ?? '';
    final likesCount = reel['likes_count'] as int? ?? 0;
    final isSaved = reel['is_saved'] as bool? ?? false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Thumbnail ────────────────────────────────────────────────
            if (thumb != null)
              Image.network(
                thumb,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _GradientThumb(),
              )
            else
              const _GradientThumb(),

            // ── Gradient scrim ────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.4, 1],
                ),
              ),
            ),

            // ── Play icon ─────────────────────────────────────────────────
            const Center(
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white54,
                size: 36,
              ),
            ),

            // ── Saved indicator ───────────────────────────────────────────
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
                  child: const Icon(Icons.bookmark,
                      color: Colors.white, size: 12),
                ),
              ),

            // ── Bottom info ───────────────────────────────────────────────
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.favorite,
                          color: Colors.white60, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        _fmt(likesCount),
                        style: GoogleFonts.poppins(
                            color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Gradient placeholder
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _NoSearchResults extends StatelessWidget {
  final VoidCallback onClear;
  const _NoSearchResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text('No results found',
              style:
                  GoogleFonts.poppins(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or hashtags',
            style:
                GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Clear Search',
              style: GoogleFonts.poppins(color: const Color(0xFF4A60D4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.video_library_outlined,
              size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text('No reels yet',
              style:
                  GoogleFonts.poppins(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Check back soon for AI prompt reels!',
            style:
                GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EmptySavedState extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptySavedState({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_border, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text('No saved reels',
              style:
                  GoogleFonts.poppins(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Tap the bookmark icon on any reel to save it.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onBrowse,
            child: Text(
              'Browse Reels',
              style: GoogleFonts.poppins(color: const Color(0xFF4A60D4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text('Failed to load reels',
              style:
                  GoogleFonts.poppins(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A60D4)),
            child:
                Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

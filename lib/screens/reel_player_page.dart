import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/screens/profile_page.dart';

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


String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _formatTime(String iso) {
  try {
    final diff = DateTime.now().difference(DateTime.parse(iso));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  } catch (_) {
    return '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reel Player Page  — full-screen vertical PageView
// ─────────────────────────────────────────────────────────────────────────────

class ReelPlayerPage extends StatefulWidget {
  final List<Map<String, dynamic>> reels;
  final int initialIndex;

  const ReelPlayerPage({
    super.key,
    required this.reels,
    required this.initialIndex,
  });

  @override
  State<ReelPlayerPage> createState() => _ReelPlayerPageState();
}

class _ReelPlayerPageState extends State<ReelPlayerPage> {
  final _api = ApiService();
  late final PageController _pageController;
  late List<Map<String, dynamic>> _reels;
  late int _currentIndex;
  DateTime? _activeFrom;

  @override
  void initState() {
    super.initState();
    _reels = List.from(widget.reels);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _activeFrom = DateTime.now();
  }

  @override
  void dispose() {
    _sendCurrentView();
    _pageController.dispose();
    super.dispose();
  }

  // ── View tracking ─────────────────────────────────────────────────────────

  void _sendCurrentView({bool isCompleted = false}) {
    if (_activeFrom == null) return;
    final ms = DateTime.now().difference(_activeFrom!).inMilliseconds;
    final id = _reels[_currentIndex]['id']?.toString() ?? '';
    if (id.isNotEmpty && ms > 0) {
      _api.recordReelView(id, ms, isCompleted: isCompleted)
        .catchError((_) => <String, dynamic>{});
    }
    _activeFrom = null;
  }

  void _onPageChanged(int i) {
    _sendCurrentView();
    setState(() => _currentIndex = i);
    _activeFrom = DateTime.now();
  }

  // ── Like / Save / Share / Comment ─────────────────────────────────────────

  void _toggleLike(int index) async {
    final reel = _reels[index];
    final id = reel['id']?.toString() ?? '';
    final wasLiked = reel['is_liked'] as bool? ?? false;

    // Optimistic
    setState(() {
      _reels[index] = {
        ..._reels[index],
        'is_liked': !wasLiked,
        'likes_count': ((reel['likes_count'] as int? ?? 0) + (wasLiked ? -1 : 1))
            .clamp(0, double.maxFinite.toInt()),
      };
    });

    try {
      final res = await _api.toggleReelLike(id);
      // Sync with server-confirmed counts
      if (mounted && res.isNotEmpty) {
        setState(() {
          _reels[index] = {
            ..._reels[index],
            'is_liked': res['liked'] as bool? ?? !wasLiked,
            'likes_count': res['likes_count'] as int? ?? _reels[index]['likes_count'],
          };
        });
      }
    } catch (_) {
      // Roll back
      if (mounted) {
        setState(() {
          _reels[index] = {
            ..._reels[index],
            'is_liked': wasLiked,
            'likes_count': reel['likes_count'] as int? ?? 0,
          };
        });
      }
    }
  }

  void _toggleSave(int index) async {
    final reel = _reels[index];
    final id = reel['id']?.toString() ?? '';
    final wasSaved = reel['is_saved'] as bool? ?? false;

    // Optimistic
    setState(() {
      _reels[index] = {
        ..._reels[index],
        'is_saved': !wasSaved,
        'saves_count': ((reel['saves_count'] as int? ?? 0) + (wasSaved ? -1 : 1))
            .clamp(0, double.maxFinite.toInt()),
      };
    });

    try {
      final res = await _api.toggleReelSave(id);
      if (mounted && res.isNotEmpty) {
        setState(() {
          _reels[index] = {
            ..._reels[index],
            'is_saved': res['saved'] as bool? ?? !wasSaved,
            'saves_count': res['saves_count'] as int? ?? _reels[index]['saves_count'],
          };
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reels[index] = {
            ..._reels[index],
            'is_saved': wasSaved,
            'saves_count': reel['saves_count'] as int? ?? 0,
          };
        });
      }
    }
  }

  void _shareReel(int index, String videoUrl) async {
    final id = _reels[index]['id']?.toString() ?? '';
    // Copy link immediately
    await Clipboard.setData(ClipboardData(text: videoUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Link copied!'), duration: Duration(seconds: 2)),
      );
    }
    // Record share on backend and sync count
    if (id.isEmpty) return;
    try {
      final res = await _api.shareReel(id);
      if (mounted && res.isNotEmpty) {
        setState(() {
          _reels[index] = {
            ..._reels[index],
            'is_shared': res['shared'] as bool? ?? true,
            'shares_count':
                res['shares_count'] as int? ?? _reels[index]['shares_count'],
          };
        });
      }
    } catch (_) {}
  }

  void _openComments(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        reelId: _reels[index]['id']?.toString() ?? '',
        onCommentAdded: () {
          if (mounted) {
            setState(() {
              final count =
                  (_reels[index]['comments_count'] as int? ?? 0) + 1;
              _reels[index] = {
                ..._reels[index],
                'comments_count': count,
              };
            });
          }
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _sendCurrentView();
          Navigator.of(context).pop(_reels);
        }
      },
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: _reels.length,
              itemBuilder: (context, index) => _ReelPlayerCard(
                reel: _reels[index],
                isActive: index == _currentIndex,
                onLike: () => _toggleLike(index),
                onSave: () => _toggleSave(index),
                onComment: () => _openComments(index),
                onShare: () => _shareReel(
                    index, _reels[index]['video_url'] as String? ?? ''),
              ),
            ),
            // Back button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 22),
                  ),
                  onPressed: () {
                    _sendCurrentView();
                    Navigator.of(context).pop(_reels);
                  },
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
//  Individual Reel Card  — contains the video + overlaid controls
// ─────────────────────────────────────────────────────────────────────────────

class _ReelPlayerCard extends StatelessWidget {
  final Map<String, dynamic> reel;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const _ReelPlayerCard({
    required this.reel,
    required this.isActive,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final title = reel['title'] as String? ?? 'Untitled';
    final description = reel['description'] as String? ?? '';
    final prompt = reel['prompt'] as String? ?? '';
    final isLiked = reel['is_liked'] as bool? ?? false;
    final isSaved = reel['is_saved'] as bool? ?? false;
    final isShared = reel['is_shared'] as bool? ?? false;
    final likesCount = reel['likes_count'] as int? ?? 0;
    final savesCount = reel['saves_count'] as int? ?? 0;
    final sharesCount = reel['shares_count'] as int? ?? 0;
    final commentsCount = reel['comments_count'] as int? ?? 0;
    final videoUrl = reel['video_url'] as String? ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Video player ─────────────────────────────────────────────────
        _InAppVideoPlayer(videoUrl: videoUrl, isActive: isActive),

        // ── Gradient overlay ─────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x77000000),
                Colors.transparent,
                Colors.transparent,
                Color(0xEE000000),
              ],
              stops: [0, 0.2, 0.55, 1],
            ),
          ),
        ),

        // ── Right-side actions ────────────────────────────────────────────
        Positioned(
          right: 10,
          bottom: 100,
          child: Column(
            children: [
              _ActionBtn(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: _formatCount(likesCount),
                color: isLiked ? Colors.redAccent : Colors.white,
                onTap: onLike,
              ),
              const SizedBox(height: 22),
              _ActionBtn(
                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                label: _formatCount(savesCount),
                color: isSaved ? const Color(0xFF4A60D4) : Colors.white,
                onTap: onSave,
              ),
              const SizedBox(height: 22),
              _ActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: _formatCount(commentsCount),
                color: Colors.white,
                onTap: onComment,
              ),
              const SizedBox(height: 22),
              _ActionBtn(
                icon: Icons.share_outlined,
                label: sharesCount > 0
                    ? _formatCount(sharesCount)
                    : 'Share',
                color: isShared ? const Color(0xFF4A60D4) : Colors.white,
                onTap: onShare,
              ),
            ],
          ),
        ),

        // ── Bottom info ───────────────────────────────────────────────────
        Positioned(
          left: 14,
          right: 68,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(blurRadius: 6, color: Colors.black)
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    shadows: const [
                      Shadow(blurRadius: 4, color: Colors.black)
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (prompt.isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: prompt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Prompt copied!'),
                          duration: Duration(seconds: 2)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A60D4).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Tap to copy AI prompt',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.keyboard_arrow_up,
                      color: Colors.white38, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    'Swipe up for next',
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  In-App Video Player  — handles YouTube & direct video URLs
// ─────────────────────────────────────────────────────────────────────────────

class _InAppVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;

  const _InAppVideoPlayer(
      {required this.videoUrl, required this.isActive});

  @override
  State<_InAppVideoPlayer> createState() => _InAppVideoPlayerState();
}

class _InAppVideoPlayerState extends State<_InAppVideoPlayer> {
  VideoPlayerController? _videoCtrl;
  YoutubePlayerController? _ytCtrl;

  bool _isYT = false;
  bool _initialized = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _isYT = _youtubeId(widget.videoUrl) != null;
    if (widget.isActive) _init();
  }

  @override
  void didUpdateWidget(_InAppVideoPlayer old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      if (_initialized) {
        _videoCtrl?.play();
        _ytCtrl?.play();
      } else {
        _init();
      }
    } else if (!widget.isActive && old.isActive) {
      _videoCtrl?.pause();
      _ytCtrl?.pause();
    }
  }

  Future<void> _init() async {
    if (widget.videoUrl.isEmpty) return;

    if (_isYT) {
      final id = _youtubeId(widget.videoUrl);
      if (id == null) return;
      _ytCtrl = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          loop: true,
          hideControls: true,
          controlsVisibleAtStart: false,
          disableDragSeek: true,
        ),
      );
      if (mounted) setState(() => _initialized = true);
    } else {
      try {
        final ctrl =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        await ctrl.initialize();
        ctrl.setLooping(true);
        ctrl.play();
        _videoCtrl = ctrl;
        if (mounted) setState(() => _initialized = true);
      } catch (_) {
        // Show thumbnail fallback
      }
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
    _videoCtrl?.dispose();
    _ytCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Not yet initialized — show thumbnail fallback
    if (!_initialized) {
      return _ThumbnailFallback(videoUrl: widget.videoUrl);
    }

    Widget player;

    if (_isYT && _ytCtrl != null) {
      // YouTube player — scale to fill screen height
      player = YoutubePlayer(
        controller: _ytCtrl!,
        showVideoProgressIndicator: false,
      );
    } else if (_videoCtrl != null &&
        _videoCtrl!.value.isInitialized) {
      player = GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fill screen with cover fit
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoCtrl!.value.size.width,
                  height: _videoCtrl!.value.size.height,
                  child: VideoPlayer(_videoCtrl!),
                ),
              ),
            ),
            // Play/pause indicator
            if (!_videoCtrl!.value.isPlaying)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 40),
              ),
          ],
        ),
      );
    } else {
      return _ThumbnailFallback(videoUrl: widget.videoUrl);
    }

    // For YouTube: scale up to fill portrait screen
    if (_isYT) {
      return GestureDetector(
        onTap: _togglePlayPause,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final videoH = w * 9 / 16;
              final scale = videoH < h ? h / videoH : 1.0;
              return Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: w,
                  height: videoH,
                  child: player,
                ),
              );
            },
          ),
        ),
      );
    }

    return player;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Thumbnail fallback  (shown while video initialises)
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailFallback extends StatelessWidget {
  final String videoUrl;
  const _ThumbnailFallback({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final id = _youtubeId(videoUrl);
    final thumbUrl = id != null
        ? 'https://img.youtube.com/vi/$id/hqdefault.jpg'
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbUrl != null)
          Image.network(thumbUrl, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _GradientBg())
        else
          const _GradientBg(),
        // Loading indicator
        const Center(
          child: CircularProgressIndicator(
              color: Colors.white54, strokeWidth: 2),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30,
              shadows: const [Shadow(blurRadius: 6, color: Colors.black)]),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Gradient background
// ─────────────────────────────────────────────────────────────────────────────

class _GradientBg extends StatelessWidget {
  const _GradientBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C1C24), Color(0xFF3B2E7E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline_rounded,
            size: 80, color: Colors.white12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Comments Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final String reelId;
  final VoidCallback onCommentAdded;

  const _CommentsSheet(
      {required this.reelId, required this.onCommentAdded});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _api = ApiService();
  final _textCtrl = TextEditingController();

  List<Map<String, dynamic>> _comments = [];
  bool _loaded = false;
  bool _submitting = false;

  String _currentUserName = '';
  String? _currentUserAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final cache = await loadProfileCache();
    if (mounted) {
      setState(() {
        _currentUserName = cache['name'] ?? '';
        _currentUserAvatarUrl = cache['avatarUrl'];
      });
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final data = await _api.getReelComments(widget.reelId);
      if (mounted) {
        setState(() {
          _comments =
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final result = await _api.addReelComment(widget.reelId, text);
      _textCtrl.clear();
      widget.onCommentAdded();
      if (mounted) {
        final newComment = result is Map
            ? Map<String, dynamic>.from(result)
            : <String, dynamic>{
                'body': text,
                'user': {
                  'name': _currentUserName.isNotEmpty
                      ? _currentUserName
                      : 'You',
                  'avatar': _currentUserAvatarUrl,
                },
                'created_at': DateTime.now().toIso8601String(),
              };
        setState(() {
          _comments.insert(0, newComment);
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              // List
              Expanded(
                child: !_loaded
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF4A60D4)))
                    : _comments.isEmpty
                        ? Center(
                            child: Text(
                              'No comments yet.\nBe the first to share a prompt!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: Colors.white38, fontSize: 14),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _comments.length,
                            separatorBuilder: (_, _) => const Divider(
                                color: Colors.white10, height: 24),
                            itemBuilder: (context, i) =>
                                _CommentItem(comment: _comments[i]),
                          ),
              ),

              // Input
              Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add a comment or AI prompt...',
                          hintStyle: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFF2C2C3E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _submit(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A60D4),
                          shape: BoxShape.circle,
                        ),
                        child: _submitting
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Comment Item
// ─────────────────────────────────────────────────────────────────────────────

class _CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;
  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    final user = comment['user'] as Map? ?? {};
    final name = user['name']?.toString() ?? 'Anonymous';
    final avatarUrl = user['avatar']?.toString() ??
        user['profile_photo_url']?.toString() ??
        user['avatar_url']?.toString();
    final body = comment['body']?.toString() ??
        comment['comment']?.toString() ??
        comment['text']?.toString() ??
        '';
    final createdAt = comment['created_at']?.toString() ?? '';
    final isPrompt = body.length > 60;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatar(
          name: name.isNotEmpty ? name : 'Anonymous',
          avatarUrl: avatarUrl,
          radius: 18,
          fontSize: 14,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + time
              Row(
                children: [
                  Text(name,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  if (createdAt.isNotEmpty)
                    Text(_formatTime(createdAt),
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),

              // AI Prompt badge
              if (isPrompt)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A60D4).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF4A60D4)
                              .withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'AI Prompt',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF4A60D4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              Text(body,
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),

              // Copy button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: body));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        isPrompt ? 'Prompt copied!' : 'Copied!'),
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded,
                        size: 13,
                        color: isPrompt
                            ? const Color(0xFF4A60D4)
                            : Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      isPrompt ? 'Copy Prompt' : 'Copy',
                      style: GoogleFonts.poppins(
                        color: isPrompt
                            ? const Color(0xFF4A60D4)
                            : Colors.white38,
                        fontSize: 11,
                        fontWeight: isPrompt
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:jocus_app/providers/auth_provider.dart';
import 'package:jocus_app/services/reaction_service.dart';
import 'package:jocus_app/models/video.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();
  final ReactionService _reactionService = ReactionService();
  final int _pageSize = 5; // Load 5 videos at a time
  List<DocumentSnapshot> _videos = [];
  Map<String, String> _videoBitIds = {};
  bool _isLoading = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMoreVideos();
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Loading more videos...');
      
      var query = FirebaseFirestore.instance
          .collection('videos')
          .where('status', isEqualTo: 'ready')
          .orderBy('uploadDate', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();
      debugPrint('Query returned ${snapshot.docs.length} videos');
      
      if (snapshot.docs.isNotEmpty) {
        // Load associated bits for each video
        final videoDocs = await Future.wait(
          snapshot.docs.map((videoDoc) async {
            final videoData = videoDoc.data() as Map<String, dynamic>;
            // Find the associated bit
            final bitQuery = await FirebaseFirestore.instance
                .collection('bits')
                .where('videoUrl', isEqualTo: videoData['storageUrl'])
                .limit(1)
                .get();
            
            String? bitId;
            if (bitQuery.docs.isNotEmpty) {
              bitId = bitQuery.docs.first.id;
              debugPrint('Found bit ${bitId} for video ${videoDoc.id}');
            } else {
              debugPrint('No bit found for video ${videoDoc.id}');
            }
            
            return {
              'doc': videoDoc,
              'bitId': bitId,
            };
          }),
        );

        setState(() {
          _videos.addAll(videoDocs.map((data) => data['doc'] as DocumentSnapshot));
          _videoBitIds.addAll(
            Map.fromEntries(
              videoDocs
                  .where((data) => data['bitId'] != null)
                  .map((data) => MapEntry(
                        (data['doc'] as DocumentSnapshot).id,
                        data['bitId'] as String,
                      )),
            ),
          );
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoading = false;
        });
      } else {
        debugPrint('No more videos found');
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _videos.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                // Load more videos when user reaches near the end
                if (index >= _videos.length - 2) {
                  _loadMoreVideos();
                }
              },
              itemCount: _videos.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _videos.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final video = _videos[index];
                final bitId = _videoBitIds[video.id];
                return VideoItem(
                  videoUrl: video['storageUrl'],
                  videoId: video.id,
                  bitId: bitId ?? '',
                  reactionService: _reactionService,
                );
              },
            ),
    );
  }
}

class VideoItem extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final String bitId;
  final ReactionService reactionService;

  const VideoItem({
    Key? key,
    required this.videoUrl,
    required this.videoId,
    required this.bitId,
    required this.reactionService,
  }) : super(key: key);

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  late VideoPlayerController _controller;
  Map<String, int> _reactionCounts = {
    'rofl': 0,
    'smirk': 0,
    'eyeroll': 0,
    'vomit': 0,
  };

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
    _loadReactionCounts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadReactionCounts() async {
    if (widget.bitId.isEmpty) {
      debugPrint('Cannot load reactions: No bit ID found for video');
      return;
    }

    try {
      final counts = await widget.reactionService.getReactionCounts(widget.bitId);
      setState(() {
        _reactionCounts = counts;
      });
    } catch (e) {
      debugPrint('Error loading reaction counts: $e');
    }
  }

  Future<void> _handleReaction(String type) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;
    if (widget.bitId.isEmpty) {
      debugPrint('Cannot add reaction: No bit ID found for video');
      return;
    }

    try {
      await widget.reactionService.addReaction(
        bitId: widget.bitId,
        userId: userId,
        reactionType: type,
        timestamp: _controller.value.position.inSeconds.toDouble(),
      );
      // Refresh counts after adding reaction
      await _loadReactionCounts();
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Transform.rotate(
            angle: 90 * 3.14159 / 180, // 90 degrees in radians
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReactionButton(
                  emoji: '🤣',
                  label: 'ROFL',
                  count: _reactionCounts['rofl'] ?? 0,
                  onTap: () => _handleReaction('rofl'),
                ),
                const SizedBox(height: 16),
                _ReactionButton(
                  emoji: '😏',
                  label: 'Smirk',
                  count: _reactionCounts['smirk'] ?? 0,
                  onTap: () => _handleReaction('smirk'),
                ),
                const SizedBox(height: 16),
                _ReactionButton(
                  emoji: '🙄',
                  label: 'Eye Roll',
                  count: _reactionCounts['eyeroll'] ?? 0,
                  onTap: () => _handleReaction('eyeroll'),
                ),
                const SizedBox(height: 16),
                _ReactionButton(
                  emoji: '🤮',
                  label: 'Vomit',
                  count: _reactionCounts['vomit'] ?? 0,
                  onTap: () => _handleReaction('vomit'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _ReactionButton({
    Key? key,
    required this.emoji,
    required this.label,
    required this.count,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
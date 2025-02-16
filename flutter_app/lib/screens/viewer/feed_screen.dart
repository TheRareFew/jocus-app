import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'package:jocus_app/providers/auth_provider.dart';
import 'package:jocus_app/services/reaction_service.dart';
import 'package:jocus_app/models/video.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../../services/face_detection_service.dart';
import 'dart:io';  // Add this import
import 'dart:math';

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
  int _currentPage = 0;
  CameraController? _cameraController;
  late Future<void> _initializeControllerFuture;
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  double? _latestSmileProbability;
  bool _isProcessing = false;
  bool _hasReacted = false;
  Duration _currentVideoPosition = Duration.zero;
  DateTime _lastProcessedTime = DateTime.now();
  Timer? _frameProcessingTimer;
  VideoItem? _currentVideoItem;
  final Map<String, GlobalKey<_VideoItemState>> _videoKeys = {};

  @override
  void initState() {
    super.initState();
    _loadMoreVideos();
    _pageController.addListener(_onPageChanged);
    _initializeCamera();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });

      // Load more videos if we're near the end
      if (page >= _videos.length - 2 && !_isLoading && _hasMore) {
        _loadMoreVideos();
      }
    }
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
                .where('storageUrl', isEqualTo: videoData['storageUrl'])
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

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      debugPrint('Available cameras: ${cameras.length}');
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      debugPrint('Selected camera: ${frontCamera.name}');
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      _initializeControllerFuture = _cameraController!.initialize();
      await _initializeControllerFuture;
      
      if (!mounted) return;
      
      debugPrint('Camera initialized successfully');
      debugPrint('Camera info: ${_cameraController!.value.description}');
      
      await _startImageStream();
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _startImageStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }

    try {
      // Instead of continuous stream, use a timer to process frames
      _frameProcessingTimer?.cancel();
      _frameProcessingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (_cameraController?.value.isInitialized ?? false) {
          final image = await _cameraController!.takePicture();
          _processImage(image);
        }
      });
      debugPrint('Frame processing timer started');
    } catch (e) {
      debugPrint('Error starting frame processing: $e');
    }
  }

  Future<void> _processImage(XFile image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final smileProb = await _faceDetectionService.detectSmile(inputImage);
      
      if (smileProb != null && mounted) {
        setState(() {
          _latestSmileProbability = smileProb;
        });

        // Only trigger reaction if we haven't reacted recently and have valid video
        if (!_hasReacted && _videos.isNotEmpty && _currentPage < _videos.length) {
          // Big smile = ROFL, slight smile = smirk
          if (smileProb >= 0.7) {
            _handleSmileReaction('rofl');
          } else if (smileProb >= 0.3) {
            _handleSmileReaction('smirk');
          }
        }
      }
      
      // Clean up the temporary image file
      final file = File(image.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing image: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _handleSmileReaction(String reactionType) async {
    if (!mounted || _hasReacted || _videos.isEmpty || _currentPage >= _videos.length) return;

    try {
      setState(() {
        _hasReacted = true;
      });

      final currentVideo = _videos[_currentPage];
      final videoKey = _videoKeys[currentVideo.id];
      
      if (videoKey?.currentState != null) {
        videoKey!.currentState!._handleReaction(reactionType);
      }

      // Reset reaction flag after a cooldown period
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _hasReacted = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error handling smile reaction: $e');
      setState(() {
        _hasReacted = false;
      });
    }
  }

  @override
  void dispose() {
    _frameProcessingTimer?.cancel();
    if (_cameraController?.value.isInitialized ?? false) {
      _cameraController?.dispose();
    }
    _faceDetectionService.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _frameProcessingTimer?.cancel();  // Cancel the timer
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: Stack(
        children: [
          // Main video feed
          _videos.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
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
                final videoData = video.data() as Map<String, dynamic>;
                final bitId = _videoBitIds[video.id];
                final videoUrl = videoData['hlsUrl'] as String? ?? videoData['storageUrl'] as String;
                
                // Get or create a key for this video
                _videoKeys[video.id] ??= GlobalKey<_VideoItemState>();
                final videoKey = _videoKeys[video.id]!;
                
                return KeyedSubtree(
                  key: ValueKey('video_${video.id}'),
                  child: VideoItem(
                    key: videoKey,
                    videoUrl: videoUrl,
                    videoId: video.id,
                    bitId: bitId ?? '',
                    reactionService: _reactionService,
                    onPositionUpdate: (Duration position) {
                      setState(() {
                        _currentVideoPosition = position;
                      });
                    },
                    onReactionUpdate: _handleReactionUpdate,
                  ),
                );
              },
            ),
          
          // Camera preview and debug overlay in top-left corner
          Positioned(
            top: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Camera preview in a small container
                if (_cameraController != null && _cameraController!.value.isInitialized)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 160,  // Small fixed height
                      width: 120,   // Small fixed width
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                
                // Small gap between camera preview and debug text
                const SizedBox(height: 8),
                
                // Debug overlay text
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Smile: ${_latestSmileProbability?.toStringAsFixed(2) ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to handle reaction updates from VideoItem
  void _handleReactionUpdate(String type, bool isActive) {
    // This method can be used to handle any side effects of reactions
    debugPrint('Reaction update: $type is now ${isActive ? 'active' : 'inactive'}');
  }
}

class VideoItem extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final String bitId;
  final ReactionService reactionService;
  final Function(Duration) onPositionUpdate;
  final Function(String, bool) onReactionUpdate;

  const VideoItem({
    Key? key,
    required this.videoUrl,
    required this.videoId,
    required this.bitId,
    required this.reactionService,
    required this.onPositionUpdate,
    required this.onReactionUpdate,
  }) : super(key: key);

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  bool _isInitializing = false;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, int> _reactionCounts = {
    'rofl': 0,
    'smirk': 0,
    'eyeroll': 0,
    'vomit': 0,
  };
  Map<String, bool> _userReactions = {
    'rofl': false,
    'smirk': false,
    'eyeroll': false,
    'vomit': false,
  };
  final List<_FloatingEmoji> _floatingEmojis = [];
  final Map<String, String> _reactionEmojis = {
    'rofl': '🤣',
    'smirk': '😏',
    'eyeroll': '🙄',
    'vomit': '🤮',
  };
  
  int _playRetryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('VideoItem initState for video ${widget.videoId}');
    _initializePlayer();
    _loadReactionCounts();
    _loadUserReactions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    debugPrint('Deactivating video: ${widget.videoId}');
    _videoController?.pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _videoController?.pause();
    }
  }

  Future<void> _initializePlayer() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      await _initializeWithUrl(widget.videoUrl);
    } catch (e) {
      debugPrint('Error initializing player for video ${widget.videoId}: $e');
    } finally {
      _isInitializing = false;
    }
  }
  
  Future<void> _initializeWithUrl(String url) async {
    debugPrint('Initializing URL: $url');
    try {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
      // Dispose any existing controller
      _disposeController();
      
      // Create a new VideoPlayerController
      _videoController = VideoPlayerController.network(url);
      await _videoController!.initialize();
      
      // Create a new ChewieController
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: true,
        aspectRatio: 9 / 16,
        showControls: false,
        allowPlaybackSpeedChanging: false,
        allowFullScreen: false,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        deviceOrientationsOnEnterFullScreen: [DeviceOrientation.portraitUp],
        allowedScreenSleep: false,
        allowMuting: false,
      );
      
      // Reset video state
      await _videoController!.seekTo(Duration.zero);
      await _videoController!.setVolume(1.0);
      
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          await _videoController!.play();
        }
      }
    } catch (e) {
      debugPrint('Error initializing URL $url: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video';
          _isPlaying = false;
        });
      }
    }
  }

  void _disposeController() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
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

  Future<void> _loadUserReactions() async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null || widget.bitId.isEmpty) return;

    try {
      final reactions = await FirebaseFirestore.instance
          .collection('bits')
          .doc(widget.bitId)
          .collection('reactions')
          .where('userId', isEqualTo: userId)
          .get();

      if (mounted) {
        setState(() {
          for (final reaction in reactions.docs) {
            final type = reaction.data()['type'] as String;
            _userReactions[type] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user reactions: $e');
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
      final videoController = _videoController;
      if (videoController == null) return;

      // Update local state immediately
      final bool newReactionState = !(_userReactions[type] ?? false);
      setState(() {
        _userReactions[type] = newReactionState;
        _reactionCounts[type] = (_reactionCounts[type] ?? 0) + (newReactionState ? 1 : -1);
      });
      
      // Show floating emoji animation if adding a reaction
      if (newReactionState) {
        _showFloatingEmoji(type);
      }
      
      // Notify parent about the reaction update
      widget.onReactionUpdate(type, newReactionState);
      
      await widget.reactionService.addReaction(
        bitId: widget.bitId,
        userId: userId,
        reactionType: type,
        timestamp: videoController.value.position.inSeconds.toDouble(),
      );

    } catch (e) {
      debugPrint('Error adding reaction: $e');
      // Revert state if there was an error
      setState(() {
        _userReactions[type] = !(_userReactions[type] ?? false);
        _reactionCounts[type] = (_reactionCounts[type] ?? 0) + (_userReactions[type]! ? 1 : -1);
      });
    }
  }

  void _showFloatingEmoji(String type) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Get the position of the reaction button
    final buttonPosition = box.localToGlobal(
      Offset(box.size.width - 66, box.size.height - 300 + (_reactionEmojis.keys.toList().indexOf(type) * 66)),
    );

    // Create and show the floating emoji
    final floatingEmoji = _FloatingEmoji(
      emoji: _reactionEmojis[type] ?? '😊',
      startPosition: buttonPosition,
    );

    // Add overlay entry
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => floatingEmoji,
    );

    overlayState.insert(overlayEntry);

    // Remove the overlay entry after animation completes
    Future.delayed(const Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = _chewieController;
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Error loading video'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
                _initializePlayer();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        if (chewieController != null)
          Chewie(
            controller: chewieController,
          )
        else
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading video...'),
              ],
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
                isActive: _userReactions['rofl'] ?? false,
              ),
              const SizedBox(height: 16),
              _ReactionButton(
                emoji: '😏',
                label: 'Smirk',
                count: _reactionCounts['smirk'] ?? 0,
                onTap: () => _handleReaction('smirk'),
                isActive: _userReactions['smirk'] ?? false,
              ),
              const SizedBox(height: 16),
              _ReactionButton(
                emoji: '🙄',
                label: 'Eye Roll',
                count: _reactionCounts['eyeroll'] ?? 0,
                onTap: () => _handleReaction('eyeroll'),
                isActive: _userReactions['eyeroll'] ?? false,
              ),
              const SizedBox(height: 16),
              _ReactionButton(
                emoji: '🤮',
                label: 'Vomit',
                count: _reactionCounts['vomit'] ?? 0,
                onTap: () => _handleReaction('vomit'),
                isActive: _userReactions['vomit'] ?? false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final VoidCallback onTap;
  final bool isActive;

  const _ReactionButton({
    Key? key,
    required this.emoji,
    required this.label,
    required this.count,
    required this.onTap,
    required this.isActive,
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
              color: isActive 
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: isActive
                ? Border.all(color: Colors.white, width: 2)
                : null,
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
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _FloatingEmoji extends StatefulWidget {
  final String emoji;
  final Offset startPosition;

  const _FloatingEmoji({
    Key? key,
    required this.emoji,
    required this.startPosition,
  }) : super(key: key);

  @override
  State<_FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<_FloatingEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create a curved animation for natural movement
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Fade animation: start visible, end transparent
    _fadeAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(curvedAnimation);

    // Slide animation: move upward with slight randomization
    final random = Random();
    final randomX = (random.nextDouble() - 0.5) * 100; // Random horizontal movement
    _slideAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.startPosition + Offset(randomX, -200), // Move upward with random horizontal
    ).animate(curvedAnimation);

    // Scale animation: start normal, slightly grow then shrink
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.5),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 0.8),
        weight: 70.0,
      ),
    ]).animate(curvedAnimation);

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                left: _slideAnimation.value.dx,
                top: _slideAnimation.value.dy,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(
                        fontSize: 40,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
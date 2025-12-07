import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:grace_academy/core/secure_flag.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/theme.dart';
import 'package:grace_academy/data/api/video_service.dart';
import 'package:grace_academy/data/models/video_quality.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  final String lectureId;

  const VideoPlayerPage({
    super.key,
    required this.lectureId,
  });

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isScreenRecordingDetected = false;

  bool _isLoading = true;
  String? _error;
  String _title = 'محاضرة';
  int _durationSeconds = 0;
  List<VideoQuality> _formats = [];
  VideoQuality? _selectedFormat;
  VideoMetadata? _currentMetadata;

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
    _initializeVideo();
  }

  @override
  void dispose() {
    _disableScreenProtection();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _enableScreenProtection() async {
    try {
      await SecureFlag.enableSecure();
    } catch (e) {
      debugPrint('Screen protection enable failed: $e');
    }
  }

  Future<void> _disableScreenProtection() async {
    try {
      await SecureFlag.disableSecure();
    } catch (e) {
      debugPrint('Screen protection disable failed: $e');
    }
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final meta = await VideoService.getVideoMetadata(ref, widget.lectureId);
      _currentMetadata = meta;
      _formats = meta.formats;

      // Load saved quality preference
      final prefs = await SharedPreferences.getInstance();
      final savedQuality = prefs.getString('preferred_quality');
      
      // Select quality: saved preference > 720p > first available
      VideoQuality? selectedFormat;
      if (savedQuality != null) {
        selectedFormat = _formats.cast<VideoQuality?>().firstWhere(
          (f) => f?.quality == savedQuality,
          orElse: () => null,
        );
      }
      selectedFormat ??= _formats.cast<VideoQuality?>().firstWhere(
        (f) => f?.quality == '720p',
        orElse: () => null,
      );
      selectedFormat ??= _formats.first;

      await _loadVideoFormat(selectedFormat, autoPlay: false);

      setState(() {
        _title = meta.title;
        _durationSeconds = meta.durationSeconds;
        _selectedFormat = selectedFormat;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVideoFormat(VideoQuality format, {bool autoPlay = true}) async {
    final currentPosition = _videoPlayerController?.value.position ?? Duration.zero;
    final wasPlaying = _videoPlayerController?.value.isPlaying ?? false;

    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    final streamUri = await VideoService.buildStreamUri(ref, format.url);
    debugPrint('[VideoPlayerPage] Loading quality ${format.quality}: $streamUri');

    _videoPlayerController = VideoPlayerController.networkUrl(streamUri);
    await _videoPlayerController!.initialize();

    if (currentPosition > Duration.zero) {
      await _videoPlayerController!.seekTo(currentPosition);
    }

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: autoPlay && wasPlaying,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: false,
      showControlsOnInitialize: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: EduPulseColors.primary,
        handleColor: EduPulseColors.primary,
        backgroundColor: EduPulseColors.divider,
        bufferedColor: EduPulseColors.primary.withValues(alpha: 0.3),
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      errorBuilder: (context, errorMessage) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text('خطأ في تشغيل الفيديو', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    setState(() {
      _selectedFormat = format;
    });
  }

  Future<void> _changeQuality(VideoQuality format) async {
    if (_selectedFormat == format) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_quality', format.quality);

    await _loadVideoFormat(format);
  }

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.high_quality, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'جودة الفيديو',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _formats.length,
              itemBuilder: (context, index) {
                final format = _formats[index];
                final isSelected = format == _selectedFormat;
                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _changeQuality(format);
                  },
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? EduPulseColors.primary : Colors.white70,
                  ),
                  title: Text(
                    format.quality,
                    style: TextStyle(
                      color: isSelected ? EduPulseColors.primary : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${format.width}x${format.height} · ${format.sizeInMB}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int secondsTotal) {
    final m = (secondsTotal ~/ 60).toString().padLeft(2, '0');
    final s = (secondsTotal % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeVideo,
                child: const Text('إعادة المحاولة'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('العودة', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildVideoPlayer(),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      children: [
        if (_chewieController != null)
          Chewie(controller: _chewieController!)
        else
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),

        if (_isScreenRecordingDetected)
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: 64,
                    color: EduPulseColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.screenRecordingDetected,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.pauseRecordingMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDuration(_durationSeconds),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedFormat != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: EduPulseColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: EduPulseColors.primary.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _showQualitySelector,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedFormat!.quality,
                            style: TextStyle(
                              color: EduPulseColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: EduPulseColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.security,
                  size: 16,
                  color: EduPulseColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.screenCaptureBlocked,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

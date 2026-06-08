import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = true,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      _controller.setLooping(widget.looping);
      if (widget.autoPlay) {
        _controller.play();
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Video initialization error: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.error_outline, color: AppColors.textSecondary, size: 40),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          if (!_controller.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 60,
              ),
            ),
        ],
      ),
    );
  }
}

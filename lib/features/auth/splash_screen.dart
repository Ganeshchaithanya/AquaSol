import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../core/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late ApiService _apiService;
  VideoPlayerController? _controller;

  bool _videoReady = false;
  bool _videoEnded = false;
  bool _authDone   = false;
  String? _authRoute;

  @override
  void initState() {
    super.initState();
    // Full immersive — no status/nav bars during splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _apiService = Provider.of<ApiService>(context, listen: false);

    _initVideo();
    _checkAuthState();

    // Hard timeout — navigate after 12s regardless
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && !_videoEnded) {
        _videoEnded = true;
        _tryNavigate();
      }
    });
  }

  // ─── Video ──────────────────────────────────────────────────────────────────

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.asset(
        'assets/images/aquasol_splash.mp4',
      );

      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }

      setState(() {
        _controller = ctrl;
        _videoReady = true;
      });

      await ctrl.setLooping(false);
      await ctrl.setVolume(0); // muted
      await ctrl.play();

      // Listen for completion
      ctrl.addListener(() {
        if (!mounted) return;
        final v = ctrl.value;
        final finished = !v.isPlaying
            && v.duration.inMilliseconds > 0
            && (v.position >= v.duration - const Duration(milliseconds: 300));
        if (finished && !_videoEnded) {
          _videoEnded = true;
          _tryNavigate();
        }
      });
    } catch (e) {
      debugPrint('[Splash] Video error: $e');
      // Video failed — show black for 2s then navigate
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && !_videoEnded) {
        _videoEnded = true;
        _tryNavigate();
      }
    }
  }

  // ─── Auth (runs in parallel, result held until video ends) ──────────────────

  Future<void> _checkAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Not logged in — go to get-started
      if (token == null) {
        _authRoute = '/get-started';
        _authDone = true;
        _tryNavigate();
        return;
      }

      // Logged in — validate token is still good
      final profile = await _apiService.getMe();
      if (profile == null) {
        // Token expired/invalid — clear and go to get-started
        await prefs.remove('access_token');
        _authRoute = '/get-started';
        _authDone = true;
        _tryNavigate();
        return;
      }

      // Token valid → straight to dashboard, no further checks
      _authRoute = '/home';
    } catch (e) {
      final isAuthErr = e.toString().contains('401') ||
          e.toString().contains('403') ||
          e.toString().contains('Unauthorized');
      if (isAuthErr) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        _authRoute = '/get-started';
      } else {
        // Network error — still go home if token exists, else get-started
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        _authRoute = token != null ? '/home' : '/get-started';
      }
    }

    _authDone = true;
    _tryNavigate();
  }

  // ─── Dual gate: navigate only when video ended AND auth resolved ─────────────

  void _tryNavigate() {
    if (!mounted) return;
    if (!_authDone || !_videoEnded) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    context.go(_authRoute ?? '/get-started');
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoReady && _controller != null
          ? Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          : const SizedBox.expand(
              child: ColoredBox(color: Colors.black), // pure black while loading
            ),
    );
  }
}

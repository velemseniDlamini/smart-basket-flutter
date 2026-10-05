import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebCameraService {
  static final WebCameraService _instance = WebCameraService._internal();
  factory WebCameraService() => _instance;
  WebCameraService._internal();

  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  bool _isInitialized = false;
  String? _error;

  bool get isInitialized => _isInitialized;
  String? get error => _error;
  html.VideoElement? get videoElement => _videoElement;

  /// Initialize web camera with mobile-optimized constraints
  Future<bool> initialize() async {
    print('WebCameraService: Starting initialization...');

    if (!kIsWeb) {
      _error = 'Web camera service only works on web platform';
      print('WebCameraService: Not on web platform');
      return false;
    }

    try {
      print('WebCameraService: Creating video element...');
      // Create video element
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..controls = false
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.pointerEvents = 'none';

      // Set playsInline attribute for iOS Safari compatibility
      _videoElement!.setAttribute('playsinline', 'true');
      print('WebCameraService: Video element created');

      // Check if mediaDevices is available
      if (html.window.navigator.mediaDevices == null) {
        _error =
            'Camera not supported: Your browser does not support camera access. Please try Chrome or Safari.';
        print('WebCameraService: mediaDevices not available');
        return false;
      }

      print('WebCameraService: Starting constraint attempts...');
      // Start with basic constraints that work on most mobile browsers
      return await _tryInitializeWithConstraints();
    } catch (e) {
      _error = 'Camera initialization failed: ${e.toString()}';
      print('WebCameraService error: $_error');
      return false;
    }
  }

  /// Try to initialize camera with progressive fallback constraints
  Future<bool> _tryInitializeWithConstraints() async {
    print('WebCameraService: Preparing constraint list...');

    // Never fall back to an unspecified camera, which may select the selfie camera.
    try {
      final constraints = {
        'video': {
          'facingMode': {'exact': 'environment'},
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      };
      _stream =
          await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      _videoElement!.srcObject = _stream;

      await _videoElement!.onLoadedMetadata.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw TimeoutException('Video metadata loading timeout'),
      );
      await _videoElement!.play();

      _isInitialized = true;
      _error = null;
      return true;
    } catch (e) {
      _stream?.getTracks().forEach((track) => track.stop());
      _stream = null;
      _error =
          'Rear camera access failed: ${e.toString()}. Check camera permission and ensure another app is not using the camera.';
      return false;
    }
  }

  /// Capture current frame as image data
  Future<Uint8List?> captureFrame() async {
    if (!_isInitialized || _videoElement == null) {
      return null;
    }

    try {
      // Create canvas to capture video frame
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );

      final context = canvas.context2D;
      context.drawImageScaled(
        _videoElement!,
        0,
        0,
        canvas.width!,
        canvas.height!,
      );

      // Convert to blob and then to Uint8List
      final blob = await canvas.toBlob('image/jpeg', 0.8);
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      await reader.onLoad.first;

      return Uint8List.fromList((reader.result as List<int>));
    } catch (e) {
      print('Error capturing frame: $e');
      return null;
    }
  }

  /// Get video dimensions
  Size get videoSize {
    if (_videoElement != null && _isInitialized) {
      return Size(
        _videoElement!.videoWidth.toDouble(),
        _videoElement!.videoHeight.toDouble(),
      );
    }
    return Size.zero;
  }

  /// Check if camera is supported
  static bool get isSupported {
    if (!kIsWeb) return false;

    try {
      return html.window.navigator.mediaDevices != null;
    } catch (e) {
      print('Camera support check failed: $e');
      return false;
    }
  }

  /// Request camera permission
  static Future<bool> requestPermission() async {
    if (!isSupported) return false;

    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': {'exact': 'environment'}
        },
        'audio': false,
      });

      // Stop the stream immediately - we just wanted to check permission
      stream.getTracks().forEach((track) => track.stop());
      return true;
    } catch (e) {
      print('Camera permission denied: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    if (_stream != null) {
      _stream!.getTracks().forEach((track) => track.stop());
      _stream = null;
    }

    if (_videoElement != null) {
      _videoElement!.pause();
      _videoElement!.srcObject = null;
      _videoElement = null;
    }

    _isInitialized = false;
    _error = null;
  }
}

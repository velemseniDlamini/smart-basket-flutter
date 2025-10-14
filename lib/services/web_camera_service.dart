import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
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
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      
      // Set playsInline attribute for iOS Safari compatibility
      _videoElement!.setAttribute('playsinline', 'true');
      print('WebCameraService: Video element created');

      // Check if mediaDevices is available
      if (html.window.navigator.mediaDevices == null) {
        _error = 'Camera not supported: Your browser does not support camera access. Please try Chrome or Safari.';
        print('WebCameraService: mediaDevices not available');
        return false;
      }

      print('WebCameraService: mediaDevices available, checking getUserMedia...');
      if (html.window.navigator.mediaDevices!.getUserMedia == null) {
        _error = 'Camera not supported: getUserMedia not available in your browser.';
        print('WebCameraService: getUserMedia not available');
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
    
    // Simplified constraint list - start with absolute basics
    final constraintsList = [
      // Ultra basic - just video
      {
        'video': true
      },
      // Basic with back camera
      {
        'video': {
          'facingMode': 'environment'
        }
      }
    ];

    for (int i = 0; i < constraintsList.length; i++) {
      try {
        final constraints = constraintsList[i];
        print('WebCameraService: Trying camera constraints ${i + 1}/${constraintsList.length}');
        print('WebCameraService: Constraints: $constraints');
        
        print('WebCameraService: Requesting camera access...');
        _stream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
        print('WebCameraService: Camera stream obtained');
        
        print('WebCameraService: Setting video source...');
        _videoElement!.srcObject = _stream;

        print('WebCameraService: Waiting for video metadata...');
        // Wait for video to be ready with timeout
        await _videoElement!.onLoadedMetadata.first.timeout(
          Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Video metadata loading timeout');
          }
        );
        
        print('WebCameraService: Starting video playback...');
        await _videoElement!.play();

        _isInitialized = true;
        _error = null;
        print('WebCameraService: Camera initialized successfully with constraints ${i + 1}');
        print('WebCameraService: Video dimensions: ${_videoElement!.videoWidth}x${_videoElement!.videoHeight}');
        return true;

      } catch (e) {
        print('WebCameraService: Camera constraints ${i + 1} failed: $e');
        print('WebCameraService: Error type: ${e.runtimeType}');
        
        // Clean up failed attempt
        if (_stream != null) {
          _stream!.getTracks().forEach((track) => track.stop());
          _stream = null;
        }
        
        if (i == constraintsList.length - 1) {
          // Last attempt failed
          _error = 'Camera access failed. Error: ${e.toString()}. Please check camera permissions and ensure no other app is using the camera.';
          print('WebCameraService: All constraint attempts failed');
          return false;
        }
        // Continue to next constraint set
        print('WebCameraService: Trying next constraint set...');
      }
    }
    
    return false;
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
        0, 0,
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
      // Check for basic navigator support
      if (html.window.navigator == null) return false;
      
      // Check for modern mediaDevices API (required for our implementation)
      return html.window.navigator.mediaDevices != null &&
             html.window.navigator.mediaDevices!.getUserMedia != null;
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
        'video': true,
        'audio': false
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

  /// Switch camera (front/back) if available
  Future<bool> switchCamera() async {
    if (!_isInitialized) return false;

    try {
      // Get current facing mode
      final currentConstraints = _stream?.getVideoTracks().first.getSettings();
      final currentFacingMode = currentConstraints?['facingMode'] ?? 'environment';
      
      // Switch to opposite facing mode
      final newFacingMode = currentFacingMode == 'environment' ? 'user' : 'environment';
      
      // Dispose current stream
      dispose();
      
      // Reinitialize with new facing mode
      final constraints = {
        'video': {
          'facingMode': newFacingMode,
          'width': {'ideal': 1280},
          'height': {'ideal': 720}
        },
        'audio': false
      };

      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      
      // Set playsInline attribute for iOS Safari compatibility
      _videoElement!.setAttribute('playsinline', 'true');

      _stream = await html.window.navigator.mediaDevices!.getUserMedia(constraints);
      _videoElement!.srcObject = _stream;

      await _videoElement!.onLoadedMetadata.first;
      await _videoElement!.play();

      _isInitialized = true;
      return true;

    } catch (e) {
      print('Error switching camera: $e');
      return false;
    }
  }
}

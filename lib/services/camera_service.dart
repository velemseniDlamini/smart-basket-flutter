import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  /// Initialize camera service
  Future<bool> initialize() async {
    try {
      // Request camera permission
      final permissionStatus = await Permission.camera.request();
      if (!permissionStatus.isGranted) {
        print('Camera permission denied');
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        print('No cameras available');
        return false;
      }

      // Initialize camera controller with back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Required for ML Kit
      );

      await _controller!.initialize();
      _isInitialized = true;

      return true;
    } catch (e) {
      print('Error initializing camera: $e');
      return false;
    }
  }

  /// Start camera preview
  Future<void> startPreview() async {
    if (_controller != null && _isInitialized) {
      try {
        await _controller!.startImageStream(_onImageStream);
      } catch (e) {
        print('Error starting camera preview: $e');
      }
    }
  }

  /// Stop camera preview
  Future<void> stopPreview() async {
    if (_controller != null) {
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        print('Error stopping camera preview: $e');
      }
    }
  }

  Future<Uint8List?> captureStillImage() async {
    final controller = _controller;
    if (controller == null || !_isInitialized) return null;

    final resumeStream = controller.value.isStreamingImages;
    if (resumeStream) await controller.stopImageStream();
    try {
      final image = await controller.takePicture();
      return await image.readAsBytes();
    } finally {
      if (resumeStream && _isInitialized && !controller.value.isStreamingImages) {
        await controller.startImageStream(_onImageStream);
      }
    }
  }

  /// Handle image stream (to be overridden by callback)
  Function(CameraImage)? _imageStreamCallback;
  
  void setImageStreamCallback(Function(CameraImage) callback) {
    _imageStreamCallback = callback;
  }

  void _onImageStream(CameraImage image) {
    _imageStreamCallback?.call(image);
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  /// Get camera preview size
  Size? get previewSize {
    if (_controller != null && _isInitialized) {
      return _controller!.value.previewSize;
    }
    return null;
  }

  /// Check if camera permission is granted
  static Future<bool> checkPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  static Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}

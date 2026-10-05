import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/web_camera_service.dart';
import '../services/gemini_vision_service.dart';
import '../models/detected_product.dart';
import '../utils/currency.dart';

class WebCameraScanner extends StatefulWidget {
  final Function(DetectedProduct) onProductDetected;
  final VoidCallback? onClose;

  const WebCameraScanner({
    super.key,
    required this.onProductDetected,
    this.onClose,
  });

  @override
  State<WebCameraScanner> createState() => _WebCameraScannerState();
}

class _WebCameraScannerState extends State<WebCameraScanner> {
  static const _automaticScanInterval = Duration(seconds: 7);

  final WebCameraService _cameraService = WebCameraService();
  final GeminiVisionService _geminiVisionService = GeminiVisionService();

  bool _isInitialized = false;
  bool _isScanning = false;
  String? _error;
  String? _analysisError;
  Timer? _scanTimer;
  final List<DetectedProduct> _detectedProducts = [];
  final String _viewId = 'camera-view-${DateTime.now().millisecondsSinceEpoch}';
  List<GeminiProductResult> _lastImageProducts = [];
  String _recognizedText = '';
  String _receiptText = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print('WebCameraScanner: Starting camera initialization...');

    if (!kIsWeb) {
      print('WebCameraScanner: Not on web platform');
      setState(() {
        _error = 'Web camera only works on web platform';
      });
      return;
    }

    print('WebCameraScanner: On web platform, checking camera support...');
    if (!WebCameraService.isSupported) {
      print('WebCameraScanner: Camera not supported according to service');
      setState(() {
        _error =
            'Camera not supported in this browser. Please try Chrome or Safari.';
      });
      return;
    }

    print('WebCameraScanner: Camera supported, initializing service...');
    try {
      final success = await _cameraService.initialize();
      print('WebCameraScanner: Service initialization result: $success');

      if (success && mounted) {
        print('WebCameraScanner: Camera initialized successfully');
        setState(() {
          _isInitialized = true;
          _error = null;
        });

        // Register the video element as a platform view
        print('WebCameraScanner: Registering video element...');
        _registerVideoElement();
        _startAutomaticScanning();
      } else {
        print('WebCameraScanner: Camera initialization failed');
        print('WebCameraScanner: Error from service: ${_cameraService.error}');
        setState(() {
          _error = _cameraService.error ?? 'Failed to initialize camera';
        });
      }
    } catch (e) {
      print('WebCameraScanner: Exception during initialization: $e');
      if (mounted) {
        setState(() {
          _error = 'Camera error: ${e.toString()}';
        });
      }
    }
  }

  void _startAutomaticScanning() {
    if (!GeminiVisionService.isConfigured) return;
    _scanTimer?.cancel();
    unawaited(_scanFrame());
    _scanTimer = Timer.periodic(
      _automaticScanInterval,
      (_) => unawaited(_scanFrame()),
    );
  }

  void _registerVideoElement() {
    if (_cameraService.videoElement != null) {
      // Register the video element for Flutter Web
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _cameraService.videoElement!,
      );
    }
  }

  Future<void> _scanFrame() async {
    if (_isScanning || !_isInitialized) return;

    setState(() {
      _isScanning = true;
    });

    try {
      if (!GeminiVisionService.isConfigured) {
        throw const GeminiVisionException(
          'Price reading needs a secure analysis service. Configure GEMINI_PROXY_URL and redeploy the app.',
        );
      }
      final frameData = await _cameraService.captureFrame();
      if (frameData == null) {
        throw const GeminiVisionException('Could not capture a camera image.');
      }
      final result = await _geminiVisionService.analyzeImage(frameData);
      if (mounted) {
        setState(() {
          _lastImageProducts = result.products;
          _recognizedText = result.recognizedText;
          _receiptText = result.receiptText;
          _analysisError = null;
        });
      }
      for (final detected in result.products) {
        if (detected.price == null || detected.price! <= 0) continue;
        final alreadyAdded = _detectedProducts.any(
          (product) =>
              product.productName.toLowerCase() == detected.name.toLowerCase(),
        );
        if (alreadyAdded) continue;
        final product = DetectedProduct(
          productName: detected.name,
          price: detected.price!,
          confidence: detected.confidence,
          boundingBox: Rect.zero,
          timestamp: DateTime.now(),
        );
        _detectedProducts.add(product);
        widget.onProductDetected(product);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _analysisError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _geminiVisionService.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Text(
                'Camera Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Troubleshooting Tips:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Allow camera permission when prompted\n'
                      '• Try refreshing the page\n'
                      '• Use Chrome or Safari for best results\n'
                      '• Ensure camera is not used by other apps',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeCamera,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onClose,
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview using HtmlElementView
          Positioned.fill(
            child: HtmlElementView(viewType: _viewId),
          ),

          // Top bar with controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                ),

                // Scanning indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isScanning ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isScanning)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.search, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _isScanning ? 'Scanning...' : 'Ready',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom overlay with detected products
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Products Seen: ${_lastImageProducts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_lastImageProducts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Latest: ${_lastImageProducts.last.name}'
                      '${_lastImageProducts.last.price == null ? '' : ' - ${formatZar(_lastImageProducts.last.price!)}'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_receiptText.isNotEmpty ||
                      _recognizedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _receiptText.isNotEmpty ? _receiptText : _recognizedText,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!GeminiVisionService.isConfigured ||
                      _analysisError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _analysisError ??
                          'Automatic price reading needs a secure analysis service.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.amberAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    GeminiVisionService.isConfigured
                        ? 'Point the rear camera at a price label. Reading runs automatically.'
                        : 'Point the rear camera at a price label. Reading is unavailable until the analysis service is configured.',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanFrame,
                    icon: const Icon(Icons.document_scanner),
                    label: Text(
                      GeminiVisionService.isConfigured
                          ? 'Read Price Label'
                          : 'Check Price Reading Setup',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scanning frame overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ScanningFramePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanning frame
class ScanningFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final double frameSize = size.width * 0.8;
    final double left = (size.width - frameSize) / 2;
    final double top = (size.height - frameSize) / 2;
    const double cornerLength = 30;

    // Draw corner brackets
    // Top left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);

    // Top right
    canvas.drawLine(Offset(left + frameSize - cornerLength, top),
        Offset(left + frameSize, top), paint);
    canvas.drawLine(Offset(left + frameSize, top),
        Offset(left + frameSize, top + cornerLength), paint);

    // Bottom left
    canvas.drawLine(Offset(left, top + frameSize - cornerLength),
        Offset(left, top + frameSize), paint);
    canvas.drawLine(Offset(left, top + frameSize),
        Offset(left + cornerLength, top + frameSize), paint);

    // Bottom right
    canvas.drawLine(Offset(left + frameSize - cornerLength, top + frameSize),
        Offset(left + frameSize, top + frameSize), paint);
    canvas.drawLine(Offset(left + frameSize, top + frameSize),
        Offset(left + frameSize, top + frameSize - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

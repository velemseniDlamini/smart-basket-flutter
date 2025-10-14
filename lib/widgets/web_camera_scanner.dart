import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/web_camera_service.dart';
import '../models/detected_product.dart';

class WebCameraScanner extends StatefulWidget {
  final Function(DetectedProduct) onProductDetected;
  final VoidCallback? onClose;

  const WebCameraScanner({
    Key? key,
    required this.onProductDetected,
    this.onClose,
  }) : super(key: key);

  @override
  State<WebCameraScanner> createState() => _WebCameraScannerState();
}

class _WebCameraScannerState extends State<WebCameraScanner> {
  final WebCameraService _cameraService = WebCameraService();
  
  bool _isInitialized = false;
  bool _isScanning = false;
  String? _error;
  List<DetectedProduct> _detectedProducts = [];
  Timer? _scanTimer;
  String _viewId = 'camera-view-${DateTime.now().millisecondsSinceEpoch}';

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
        _error = 'Camera not supported in this browser. Please try Chrome or Safari.';
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
        
        // Start periodic scanning
        print('WebCameraScanner: Starting periodic scanning...');
        _startPeriodicScanning();
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

  void _registerVideoElement() {
    if (_cameraService.videoElement != null) {
      // Register the video element for Flutter Web
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _cameraService.videoElement!,
      );
    }
  }

  void _startPeriodicScanning() {
    // Scan every 2 seconds for better performance on mobile
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isScanning && _isInitialized) {
        _scanFrame();
      }
    });
  }

  Future<void> _scanFrame() async {
    if (_isScanning || !_isInitialized) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final frameData = await _cameraService.captureFrame();
      if (frameData != null) {
        // Simulate text recognition for demo
        // In a real implementation, you'd use a web-compatible OCR library
        await _simulateTextRecognition();
      }
    } catch (e) {
      print('Error scanning frame: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _simulateTextRecognition() async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate finding products (for demo purposes)
    if (_detectedProducts.length < 3) {
      final demoProducts = [
        DetectedProduct(
          productName: 'Coca Cola 330ml',
          price: 15.99,
          confidence: 0.85,
          boundingBox: const Rect.fromLTWH(100, 200, 150, 50),
          timestamp: DateTime.now(),
        ),
        DetectedProduct(
          productName: 'Bread White Loaf',
          price: 12.50,
          confidence: 0.92,
          boundingBox: const Rect.fromLTWH(200, 300, 180, 60),
          timestamp: DateTime.now(),
        ),
        DetectedProduct(
          productName: 'Milk 1L',
          price: 18.75,
          confidence: 0.78,
          boundingBox: const Rect.fromLTWH(150, 250, 120, 80),
          timestamp: DateTime.now(),
        ),
      ];

      // Randomly add a product
      if (DateTime.now().millisecond % 3 == 0) {
        final randomProduct = demoProducts[_detectedProducts.length];
        setState(() {
          _detectedProducts.add(randomProduct);
        });
        widget.onProductDetected(randomProduct);
      }
    }
  }

  Future<void> _switchCamera() async {
    final success = await _cameraService.switchCamera();
    if (success) {
      _registerVideoElement();
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
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
              Text(
                'Camera Error',
                style: const TextStyle(
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
                
                // Switch camera button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: _switchCamera,
                  ),
                ),
                
                // Scanning indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    'Products Detected: ${_detectedProducts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_detectedProducts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Latest: ${_detectedProducts.last.productName} - R${_detectedProducts.last.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Point camera at products to scan',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
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
    final double cornerLength = 30;

    // Draw corner brackets
    // Top left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);

    // Top right
    canvas.drawLine(Offset(left + frameSize - cornerLength, top), Offset(left + frameSize, top), paint);
    canvas.drawLine(Offset(left + frameSize, top), Offset(left + frameSize, top + cornerLength), paint);

    // Bottom left
    canvas.drawLine(Offset(left, top + frameSize - cornerLength), Offset(left, top + frameSize), paint);
    canvas.drawLine(Offset(left, top + frameSize), Offset(left + cornerLength, top + frameSize), paint);

    // Bottom right
    canvas.drawLine(Offset(left + frameSize - cornerLength, top + frameSize), Offset(left + frameSize, top + frameSize), paint);
    canvas.drawLine(Offset(left + frameSize, top + frameSize), Offset(left + frameSize, top + frameSize - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

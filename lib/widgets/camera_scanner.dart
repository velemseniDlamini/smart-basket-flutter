import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/camera_service.dart';
import '../services/text_recognition_service.dart';
import '../models/detected_product.dart';

class CameraScanner extends StatefulWidget {
  final Function(DetectedProduct) onProductDetected;
  final VoidCallback? onClose;

  const CameraScanner({
    Key? key,
    required this.onProductDetected,
    this.onClose,
  }) : super(key: key);

  @override
  State<CameraScanner> createState() => _CameraScannerState();
}

class _CameraScannerState extends State<CameraScanner> {
  final CameraService _cameraService = CameraService();
  final TextRecognitionService _textRecognitionService = TextRecognitionService();
  
  bool _isInitialized = false;
  bool _isScanning = false;
  List<DetectedProduct> _detectedProducts = [];
  RecognizedText? _recognizedText;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final success = await _cameraService.initialize();
    if (success) {
      setState(() {
        _isInitialized = true;
      });
      
      // Set up image stream callback
      _cameraService.setImageStreamCallback(_processImage);
      await _cameraService.startPreview();
      
      // Start periodic scanning
      _startPeriodicScanning();
    } else {
      _showError('Failed to initialize camera');
    }
  }

  void _startPeriodicScanning() {
    // Process every 500ms to balance performance and responsiveness
    _scanTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isScanning) {
        setState(() {
          _isScanning = true;
        });
      }
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (!_isScanning) return;

    try {
      final recognizedText = await _textRecognitionService.processImage(image);
      if (recognizedText != null && mounted) {
        setState(() {
          _recognizedText = recognizedText;
          _isScanning = false;
        });

        // Parse products from recognized text
        final products = _textRecognitionService.parseProducts(recognizedText);
        _updateDetectedProducts(products);
      }
    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _updateDetectedProducts(List<DetectedProduct> newProducts) {
    for (final product in newProducts) {
      // Check if product is already detected (avoid duplicates)
      final existingIndex = _detectedProducts.indexWhere(
        (existing) => existing.productName.toLowerCase() == product.productName.toLowerCase(),
      );

      if (existingIndex == -1) {
        // New product detected
        setState(() {
          _detectedProducts.add(product);
        });
        widget.onProductDetected(product);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _cameraService.stopPreview();
    _cameraService.dispose();
    _textRecognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: CameraPreview(_cameraService.controller!),
          ),
          
          // Text detection overlay
          if (_recognizedText != null)
            Positioned.fill(
              child: CustomPaint(
                painter: TextDetectionPainter(
                  recognizedText: _recognizedText!,
                  cameraPreviewSize: _cameraService.previewSize ?? Size.zero,
                ),
              ),
            ),
          
          // Top bar with close button and scanning indicator
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
          
          // Bottom overlay with detected products count
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

/// Custom painter for text detection bounding boxes
class TextDetectionPainter extends CustomPainter {
  final RecognizedText recognizedText;
  final Size cameraPreviewSize;

  TextDetectionPainter({
    required this.recognizedText,
    required this.cameraPreviewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (final TextBlock block in recognizedText.blocks) {
      for (final TextLine line in block.lines) {
        final Rect boundingBox = _scaleRect(line.boundingBox, size);
        
        // Draw filled rectangle
        canvas.drawRect(boundingBox, fillPaint);
        
        // Draw border
        canvas.drawRect(boundingBox, paint);
        
        // Draw text
        final textPainter = TextPainter(
          text: TextSpan(
            text: line.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(boundingBox.left, boundingBox.top - 15),
        );
      }
    }
  }

  Rect _scaleRect(Rect rect, Size canvasSize) {
    final double scaleX = canvasSize.width / cameraPreviewSize.width;
    final double scaleY = canvasSize.height / cameraPreviewSize.height;
    
    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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

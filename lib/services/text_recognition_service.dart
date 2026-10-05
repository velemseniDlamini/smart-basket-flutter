import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/detected_product.dart';

class TextRecognitionService {
  static final TextRecognitionService _instance = TextRecognitionService._internal();
  factory TextRecognitionService() => _instance;
  TextRecognitionService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessing = false;

  /// Process camera image for text recognition
  Future<RecognizedText?> processImage(CameraImage image) async {
    if (_isProcessing) return null;
    
    _isProcessing = true;
    
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return null;
      
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText;
    } catch (e) {
      print('Error processing image: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // For web, we'll use a simpler approach
      // Convert the first plane to bytes
      final bytes = image.planes.first.bytes;
      
      // Create InputImage from bytes with minimal metadata
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  /// Parse detected text into products
  List<DetectedProduct> parseProducts(RecognizedText recognizedText) {
    final List<DetectedProduct> products = [];
    
    for (final TextBlock block in recognizedText.blocks) {
      for (final TextLine line in block.lines) {
        final product = _parseProductFromLine(line);
        if (product != null) {
          products.add(product);
        }
      }
    }
    
    return products;
  }

  /// Parse a single text line for product information
  DetectedProduct? _parseProductFromLine(TextLine line) {
    final text = line.text.trim();
    if (text.isEmpty || text.length < 3) return null;

    // Price patterns for South African stores
    final pricePatterns = [
      RegExp(r'R\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'(\d+\.\d{2})\s*R?', caseSensitive: false),
      RegExp(r'(\d{2,3})\s*c', caseSensitive: false), // cents
    ];

    double? price;
    String productName = text;

    // Extract price
    for (final pattern in pricePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final priceStr = match.group(1);
        if (priceStr != null) {
          price = double.tryParse(priceStr);
          if (price != null) {
            // Remove price from product name
            productName = text.replaceAll(pattern, '').trim();
            break;
          }
        }
      }
    }

    // Skip if no valid price found or price is unreasonable
    if (price == null || price <= 0 || price > 1000) return null;

    // Clean up product name
    productName = _cleanProductName(productName);
    if (productName.isEmpty || productName.length < 2) return null;

    return DetectedProduct(
      productName: productName,
      price: price,
      confidence: _calculateConfidence(line),
      boundingBox: line.boundingBox,
      timestamp: DateTime.now(),
    );
  }

  /// Clean up product name
  String _cleanProductName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Calculate confidence score based on text recognition
  double _calculateConfidence(TextLine line) {
    // Simple confidence calculation based on text length and character types
    final text = line.text;
    double confidence = 0.5; // Base confidence
    
    // Increase confidence for longer text
    if (text.length > 5) confidence += 0.2;
    if (text.length > 10) confidence += 0.1;
    
    // Increase confidence if contains letters and numbers
    if (RegExp(r'[a-zA-Z]').hasMatch(text) && RegExp(r'\d').hasMatch(text)) {
      confidence += 0.2;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}

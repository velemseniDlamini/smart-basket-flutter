import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class GeminiProductResult {
  final String name;
  final double? price;
  final double confidence;

  const GeminiProductResult({
    required this.name,
    required this.price,
    required this.confidence,
  });
}

class GeminiScanResult {
  final List<GeminiProductResult> products;
  final String recognizedText;
  final String receiptText;

  const GeminiScanResult({
    required this.products,
    required this.recognizedText,
    required this.receiptText,
  });
}

class GeminiVisionService {
  static const _endpoint = String.fromEnvironment(
    'GEMINI_PROXY_URL',
    defaultValue: '',
  );

  static bool get isConfigured {
    final uri = Uri.tryParse(_endpoint);
    return uri != null &&
        (uri.scheme == 'https' ||
            (uri.scheme == 'http' &&
                (uri.host == 'localhost' || uri.host == '127.0.0.1')));
  }

  final http.Client _client = http.Client();

  Future<GeminiScanResult> analyzeImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    if (!isConfigured) {
      throw const GeminiVisionException(
        'Price reading needs a secure analysis service. Configure GEMINI_PROXY_URL and redeploy the app.',
      );
    }

    final response = await _client
        .post(
          Uri.parse(_endpoint),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image_base64': base64Encode(imageBytes),
            'mime_type': mimeType,
          }),
        )
        .timeout(const Duration(seconds: 55));

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw GeminiVisionException(
        body['error'] as String? ??
            'Image analysis failed (${response.statusCode})',
      );
    }

    final rawProducts = body['products'];
    if (rawProducts is! List) {
      throw const GeminiVisionException(
          'The image analysis response was invalid.');
    }

    final products = <GeminiProductResult>[];
    for (final rawProduct in rawProducts) {
      if (rawProduct is! Map<String, dynamic>) continue;
      final name = rawProduct['name'];
      if (name is! String || name.trim().isEmpty) continue;
      final priceValue = rawProduct['price'];
      final confidenceValue = rawProduct['confidence'];
      products.add(
        GeminiProductResult(
          name: name.trim(),
          price: priceValue is num ? priceValue.toDouble() : null,
          confidence: confidenceValue is num
              ? confidenceValue.toDouble().clamp(0.0, 1.0)
              : 0.0,
        ),
      );
    }

    return GeminiScanResult(
      products: products,
      recognizedText: body['recognized_text'] as String? ?? '',
      receiptText: body['receipt_text'] as String? ??
          body['recognized_text'] as String? ??
          '',
    );
  }

  void dispose() => _client.close();
}

class GeminiVisionException implements Exception {
  final String message;

  const GeminiVisionException(this.message);

  @override
  String toString() => message;
}

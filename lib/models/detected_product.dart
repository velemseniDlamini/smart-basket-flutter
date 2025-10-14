import 'dart:ui';

class DetectedProduct {
  final String productName;
  final double price;
  final double confidence;
  final Rect boundingBox;
  final DateTime timestamp;
  int quantity;

  DetectedProduct({
    required this.productName,
    required this.price,
    required this.confidence,
    required this.boundingBox,
    required this.timestamp,
    this.quantity = 1,
  });

  /// Create a copy with updated quantity
  DetectedProduct copyWith({
    String? productName,
    double? price,
    double? confidence,
    Rect? boundingBox,
    DateTime? timestamp,
    int? quantity,
  }) {
    return DetectedProduct(
      productName: productName ?? this.productName,
      price: price ?? this.price,
      confidence: confidence ?? this.confidence,
      boundingBox: boundingBox ?? this.boundingBox,
      timestamp: timestamp ?? this.timestamp,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Calculate line total
  double get lineTotal => price * quantity;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'price': price,
      'confidence': confidence,
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'right': boundingBox.right,
        'bottom': boundingBox.bottom,
      },
      'timestamp': timestamp.toIso8601String(),
      'quantity': quantity,
    };
  }

  /// Create from JSON
  factory DetectedProduct.fromJson(Map<String, dynamic> json) {
    final boundingBoxData = json['boundingBox'] as Map<String, dynamic>;
    return DetectedProduct(
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: Rect.fromLTRB(
        (boundingBoxData['left'] as num).toDouble(),
        (boundingBoxData['top'] as num).toDouble(),
        (boundingBoxData['right'] as num).toDouble(),
        (boundingBoxData['bottom'] as num).toDouble(),
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  @override
  String toString() {
    return 'DetectedProduct(name: $productName, price: R$price, quantity: $quantity, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectedProduct &&
        other.productName == productName &&
        other.price == price;
  }

  @override
  int get hashCode => productName.hashCode ^ price.hashCode;
}

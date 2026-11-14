import 'package:flutter/widgets.dart';
import '../models/detected_product.dart';

/// Stand-in for [WebCameraScanner] on platforms without `dart:html`. Native
/// platforms use `CameraScanner` instead, so this is never shown.
class WebCameraScanner extends StatelessWidget {
  final Function(DetectedProduct) onProductDetected;
  final VoidCallback? onClose;

  const WebCameraScanner({
    super.key,
    required this.onProductDetected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

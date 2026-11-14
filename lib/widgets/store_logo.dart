import 'package:flutter/material.dart';

class StoreLogo extends StatelessWidget {
  final String storeId;

  const StoreLogo({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    if (storeId == 'shoprite') {
      return const _ShopriteLogo();
    }
    if (storeId == 'spar') {
      return const _SparLogo();
    }
    return const Icon(Icons.storefront_outlined, size: 44);
  }
}

class _ShopriteLogo extends StatelessWidget {
  const _ShopriteLogo();

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFD20A0A);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 58,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: red,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Georgia',
                  fontSize: 53,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                ),
              ),
              Positioned(
                top: 0,
                child: Container(width: 4, height: 7, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                child: Container(width: 4, height: 7, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'SHOPRITE',
          style: TextStyle(
            color: red,
            fontFamily: 'Georgia',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _SparLogo extends StatelessWidget {
  const _SparLogo();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00843D);
    const red = Color(0xFFD71920);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: green, width: 4),
          ),
          padding: const EdgeInsets.all(5),
          child: const CustomPaint(painter: _SparTreePainter(green)),
        ),
        const SizedBox(height: 3),
        Container(
          width: 70,
          height: 18,
          alignment: Alignment.center,
          color: red,
          child: const Text(
            'SPAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SparTreePainter extends CustomPainter {
  final Color color;

  const _SparTreePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width * 0.08, size.height * 0.68)
      ..lineTo(size.width * 0.39, size.height * 0.68)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width * 0.61, size.height * 0.68)
      ..lineTo(size.width * 0.92, size.height * 0.68)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparTreePainter oldDelegate) =>
      oldDelegate.color != color;
}

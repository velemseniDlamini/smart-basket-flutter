import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/store.dart';

class StoreSelectionScreen extends StatelessWidget {
  const StoreSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Basket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AppState>().logout();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${appState.currentUser?.name ?? 'Shopper'}! 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Where are you shopping today?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4a5568),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Store grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: Store.availableStores.length,
                    itemBuilder: (context, index) {
                      final store = Store.availableStores[index];
                      return _StoreCard(
                        store: store,
                        onTap: () {
                          context.read<AppState>().selectStore(store);
                        },
                      );
                    },
                  ),
                ),

                // Bottom info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select your store to start scanning products with AI-powered text recognition',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const _StoreCard({
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 76,
              child: Center(
                child: _StoreLogo(storeId: store.id),
              ),
            ),

            // Store name
            Text(
              store.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2d3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Store description
            if (store.description != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  store.description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoreLogo extends StatelessWidget {
  final String storeId;

  const _StoreLogo({required this.storeId});

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

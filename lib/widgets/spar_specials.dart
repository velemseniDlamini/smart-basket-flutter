import 'package:flutter/material.dart';
import '../models/store.dart';
import '../services/live_catalog_service.dart';
import '../utils/links.dart';
import 'product_card.dart';

const _ink = Color(0xFF1E2B22);
const _muted = Color(0xFF6B7280);

/// Loads SPAR's current specials from spar.co.za and builds [builder] with
/// them, showing a spinner while they load and a message if they can't.
class SparSpecialsBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, List<LiveProduct> specials)
      builder;

  /// Height of the loading and unavailable placeholders.
  final double placeholderHeight;

  const SparSpecialsBuilder({
    super.key,
    required this.builder,
    this.placeholderHeight = 240,
  });

  @override
  State<SparSpecialsBuilder> createState() => _SparSpecialsBuilderState();
}

class _SparSpecialsBuilderState extends State<SparSpecialsBuilder> {
  @override
  void initState() {
    super.initState();
    LiveCatalogService.instance.requestSparSpecials();
  }

  @override
  Widget build(BuildContext context) {
    final service = LiveCatalogService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final specials = service.sparSpecials;
        if (specials != null && specials.isNotEmpty) {
          return widget.builder(context, specials);
        }
        return SizedBox(
          height: widget.placeholderHeight,
          child: Center(
            child: service.sparSpecialsLoading
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SPAR specials are unavailable right now',
                        style: TextStyle(color: _muted),
                      ),
                      TextButton(
                        onPressed: () => openSparSpecials(context),
                        child: const Text('Open spar.co.za'),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

void openSparSpecials(BuildContext context) {
  final store = Store.availableStores.firstWhere((s) => s.id == 'spar');
  openExternal(context, Uri.parse(store.specialsUrl), title: 'SPAR specials');
}

/// A SPAR special with its real photo and price from spar.co.za.
class SparSpecialCard extends StatelessWidget {
  final LiveProduct special;

  const SparSpecialCard({super.key, required this.special});

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(Icons.local_offer_outlined, size: 40);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openSparSpecials(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: special.imageUrl == null
                          ? fallback
                          : Image.network(
                              special.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => fallback,
                            ),
                    ),
                    if (special.badge != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD71920),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            special.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                special.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              if (special.size != null)
                Text(
                  special.size!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              const SizedBox(height: 6),
              LivePrice(product: special),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/catalog_product.dart';
import '../models/store.dart';
import '../services/live_catalog_service.dart';
import '../utils/links.dart';

/// Catalogue item that opens the product on the store's official website.
/// Where the store has an online catalogue (and the platform can load it),
/// the card shows the live photo, name and price from that website.
class ProductCard extends StatefulWidget {
  final CatalogProduct product;
  final Store store;

  const ProductCard({super.key, required this.product, required this.store});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool get _usesLiveData =>
      supportsInAppWebView && LiveCatalogService.supports(widget.store);

  @override
  void initState() {
    super.initState();
    _requestLiveData();
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        oldWidget.product != widget.product) {
      _requestLiveData();
    }
  }

  void _requestLiveData() {
    if (_usesLiveData) {
      LiveCatalogService.instance.request(
        widget.store,
        widget.product.searchTerm,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_usesLiveData) {
      return _buildCard(context, null, loading: false, notOnSpecial: false);
    }
    final service = LiveCatalogService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => _buildCard(
        context,
        service.productFor(widget.store, widget.product.searchTerm),
        loading: service.isLoading(widget.store, widget.product.searchTerm),
        notOnSpecial: widget.store.id == 'spar' && service.sparSpecials != null,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    LiveProduct? live, {
    required bool loading,
    required bool notOnSpecial,
  }) {
    final product = widget.product;
    final store = widget.store;
    final category = ProductCategory.named(product.category);
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openExternal(
          context,
          store.productUrl(product.searchTerm),
          title: store.hasOnlineCatalogue ? product.name : '${store.name} specials',
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: live?.imageUrl != null ? Colors.white : category.tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  child: _ProductImage(
                    imageUrl: live?.imageUrl,
                    emoji: product.emoji,
                    loading: loading,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                live?.name ?? product.name,
                maxLines: live == null ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2B22),
                ),
              ),
              if (live == null) ...[
                const SizedBox(height: 2),
                Text(
                  '${product.size} · ${product.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: live != null
                        ? LivePrice(product: live)
                        : Text(
                            loading
                                ? 'Loading price...'
                                : notOnSpecial
                                    ? 'Not on special'
                                    : store.hasOnlineCatalogue
                                    ? 'See price'
                                    : 'See specials',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String emoji;
  final bool loading;

  const _ProductImage({
    required this.imageUrl,
    required this.emoji,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Text(emoji, style: const TextStyle(fontSize: 46));
    final url = imageUrl;
    if (url == null) {
      return loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : fallback;
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
      ),
    );
  }
}

/// Live price with the old price or deal label when there is one.
class LivePrice extends StatelessWidget {
  final LiveProduct product;

  const LivePrice({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final onPromotion = product.wasPrice != null || product.badge != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.priceLabel != null)
          Text(
            product.priceLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          children: [
            Text(
              product.price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: onPromotion
                    ? const Color(0xFFC62828)
                    : const Color(0xFF1E2B22),
              ),
            ),
            if (product.wasPrice != null)
              Text(
                product.wasPrice!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

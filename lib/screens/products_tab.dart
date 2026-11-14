import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/catalog_product.dart';
import '../models/store.dart';
import '../services/live_catalog_service.dart' show LiveProduct;
import '../services/app_state.dart';
import '../utils/links.dart';
import '../widgets/product_card.dart';
import '../widgets/spar_specials.dart';
import '../widgets/store_logo.dart';

const _ink = Color(0xFF1E2B22);
const _muted = Color(0xFF6B7280);

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final _searchController = TextEditingController();
  Store? _store;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final store =
        _store ?? appState.selectedStore ?? Store.availableStores.first;
    final category = appState.productCategory;
    final query = _searchController.text.trim().toLowerCase();
    final products = CatalogProduct.all.where((product) {
      if (category != null && product.category != category) return false;
      return query.isEmpty || product.name.toLowerCase().contains(query);
    }).toList();
    // SPAR has no online product search, so instead of generic products
    // (which would have no real photo or price) show its live specials.
    final showSparSpecials = store.id == 'spar' && supportsInAppWebView;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<Store>(
                    showSelectedIcon: false,
                    segments: [
                      for (final option in Store.availableStores)
                        ButtonSegment(value: option, label: Text(option.name)),
                    ],
                    selected: {store},
                    onSelectionChanged: (selection) =>
                        setState(() => _store = selection.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: const Color(0xFFC8E6C9),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty && store.hasOnlineCatalogue) {
                        openExternal(
                          context,
                          store.productUrl(value),
                          title: 'Search: ${value.trim()}',
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () =>
                                  setState(_searchController.clear),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OfficialSiteBanner(store: store),
                ],
              ),
            ),
          ),
          if (showSparSpecials)
            SliverToBoxAdapter(
              child: SparSpecialsBuilder(
                builder: (context, specials) =>
                    _SparSpecialsGrid(specials: specials, query: query),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: category == null,
                      onTap: () => appState.setProductCategory(null),
                    ),
                    for (final option in ProductCategory.all)
                      _CategoryChip(
                        label: option.name,
                        selected: category == option.name,
                        onTap: () => appState.setProductCategory(option.name),
                      ),
                  ],
                ),
              ),
            ),
            if (query.isNotEmpty && store.hasOnlineCatalogue)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(Icons.travel_explore_rounded),
                    title: Text(
                      'Search ${store.websiteLabel} for "${_searchController.text.trim()}"',
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => openExternal(
                      context,
                      store.productUrl(_searchController.text),
                      title: 'Search: ${_searchController.text.trim()}',
                    ),
                  ),
                ),
              ),
            if (products.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No matching products',
                    style: TextStyle(color: _muted, fontSize: 15),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 240,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) =>
                      ProductCard(product: products[index], store: store),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SparSpecialsGrid extends StatelessWidget {
  final List<LiveProduct> specials;
  final String query;

  const _SparSpecialsGrid({required this.specials, required this.query});

  @override
  Widget build(BuildContext context) {
    final matches = specials
        .where((s) => query.isEmpty || s.name.toLowerCase().contains(query))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Text(
            "This week's SPAR specials (${matches.length})",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ),
        if (matches.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No SPAR specials match your search',
                style: TextStyle(color: _muted, fontSize: 15),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 260,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: matches.length,
            itemBuilder: (context, index) =>
                SparSpecialCard(special: matches[index]),
          ),
      ],
    );
  }
}

class _OfficialSiteBanner extends StatelessWidget {
  final Store store;

  const _OfficialSiteBanner({required this.store});

  @override
  Widget build(BuildContext context) {
    final subtitle = store.hasOnlineCatalogue
        ? 'Live prices and the full catalogue on ${store.websiteLabel}'
        : '${store.name} sells online through the SPAR2U app. '
            'See this week\'s official specials.';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openExternal(
          context,
          Uri.parse(
            store.hasOnlineCatalogue ? store.websiteUrl : store.specialsUrl,
          ),
          title:
              store.hasOnlineCatalogue ? store.name : '${store.name} specials',
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: FittedBox(child: StoreLogo(storeId: store.id)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.hasOnlineCatalogue
                          ? 'Official ${store.name} website'
                          : '${store.name} specials',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded, size: 20, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _ink,
        ),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    );
  }
}

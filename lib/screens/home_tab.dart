import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/catalog_product.dart';
import '../models/store.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';
import '../utils/links.dart';
import '../widgets/product_card.dart';
import '../widgets/spar_specials.dart';
import 'savings_cards_screen.dart';
import '../widgets/store_logo.dart';

const _ink = Color(0xFF1E2B22);
const _muted = Color(0xFF6B7280);

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final firstName =
        (appState.currentUser?.name ?? 'Shopper').split(' ').first;
    final popularStore = appState.selectedStore ?? Store.availableStores.first;
    final popular = CatalogProduct.all.where((p) => p.popular).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Expanded(child: _LocationHeader()),
                InkWell(
                  onTap: () => appState.setTab(3),
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFC8E6C9),
                    child: Text(
                      firstName.isEmpty ? '?' : firstName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Hi $firstName,\n'),
                  const TextSpan(
                    text: 'what are we buying today?',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 26, height: 1.25, color: _ink),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => appState.showProducts(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: _muted),
                      SizedBox(width: 12),
                      Text(
                        'Search milk, bread, rice...',
                        style: TextStyle(color: _muted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _ScanBanner(),
          ),
          _SectionTitle(
            'Savings cards',
            action: appState.savingsCards.isEmpty ? null : 'Manage',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavingsCardsScreen()),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final card in appState.savingsCards)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: SizedBox(
                      width: 210,
                      child: SavingsCardView(
                        card: card,
                        compact: true,
                        onTap: () => showSavingsCardBarcode(context, card),
                      ),
                    ),
                  ),
                const _AddCardTile(),
              ],
            ),
          ),
          const _SectionTitle('Choose a store'),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: Store.availableStores.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) =>
                  _StoreTile(store: Store.availableStores[index]),
            ),
          ),
          const _SectionTitle('Categories'),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: ProductCategory.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final category = ProductCategory.all[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => appState.showProducts(category: category.name),
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: category.tint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _SectionTitle(
            popularStore.id == 'spar' && supportsInAppWebView
                ? 'Specials at SPAR'
                : 'Popular at ${popularStore.name}',
            action: 'See all',
            onAction: () => appState.showProducts(),
          ),
          if (popularStore.id == 'spar' && supportsInAppWebView)
            SparSpecialsBuilder(
              builder: (context, specials) => SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: specials.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) => SizedBox(
                    width: 160,
                    child: SparSpecialCard(special: specials[index]),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: popular.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) => SizedBox(
                  width: 160,
                  child:
                      ProductCard(product: popular[index], store: popularStore),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final label = appState.isLocating
        ? 'Detecting...'
        : appState.locationStatus == LocationStatus.granted
            ? appState.locationLabel ?? 'Current location'
            : 'Set your location';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: appState.isLocating ? null : appState.requestLocation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: primary, size: 26),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shopping near',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _ink),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanBanner extends StatelessWidget {
  const _ScanBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Know your total\nbefore the till',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scan shelf labels as you shop.',
                  style: TextStyle(color: Color(0xFFE8F5E9), fontSize: 13),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => context.read<AppState>().setTab(2),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Start scanning',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  final Store store;

  const _StoreTile({required this.store});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (appState.selectedStore != store) appState.selectStore(store);
          appState.setTab(2);
        },
        child: SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: FittedBox(child: StoreLogo(storeId: store.id)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.description ?? '',
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shop now →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
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

class _AddCardTile extends StatelessWidget {
  const _AddCardTile();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 150,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showAddSavingsCardSheet(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE8F5E9),
                child: Icon(Icons.add_card_rounded, color: primary),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add a card',
                style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
              ),
              const Text(
                'Xtra Savings, Rewards',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionTitle(this.title, {this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

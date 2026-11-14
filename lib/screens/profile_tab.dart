import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/store.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';
import '../utils/links.dart';
import 'savings_cards_screen.dart';

const _ink = Color(0xFF1E2B22);
const _muted = Color(0xFF6B7280);

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to keep shopping.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppState>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final name = user?.name ?? 'Shopper';
    final locationText = switch (appState.locationStatus) {
      LocationStatus.granted => appState.locationLabel ?? 'Current location',
      LocationStatus.denied => 'Permission not granted',
      LocationStatus.serviceDisabled => 'Location services are off',
      LocationStatus.unknown => 'Not set',
    };

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFC8E6C9),
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(color: _muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _GroupLabel('Shopping'),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Location'),
                subtitle: Text(appState.isLocating ? 'Detecting...' : locationText),
                trailing: const Icon(Icons.refresh_rounded),
                onTap: appState.isLocating ? null : appState.requestLocation,
              ),
              ListTile(
                leading: const Icon(Icons.wallet_rounded),
                title: const Text('Savings cards'),
                subtitle: Text(
                  appState.savingsCards.isEmpty
                      ? 'Add your Xtra Savings or SPAR Rewards card'
                      : '${appState.savingsCards.length} saved',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavingsCardsScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Current store'),
                subtitle: Text(appState.selectedStore?.name ?? 'None selected'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => appState.setTab(2),
              ),
            ],
          ),
          const _GroupLabel('Official websites'),
          _Group(
            children: [
              for (final store in Store.availableStores)
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(store.websiteLabel),
                  subtitle: Text('${store.name} official website'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () =>
                      openExternal(
                    context,
                    Uri.parse(store.websiteUrl),
                    title: store.name,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: _muted,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: ListTile.divideTiles(context: context, tiles: children)
            .toList(),
      ),
    );
  }
}

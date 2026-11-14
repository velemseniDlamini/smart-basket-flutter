import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/app_state.dart';
import '../services/live_catalog_service.dart';
import '../utils/links.dart';
import 'home_tab.dart';
import 'products_tab.dart';
import 'profile_tab.dart';
import 'shopping_screen.dart';
import 'store_selection_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          // Hidden browser that reads live photos and prices from the store's
          // official website for the product cards. It needs a real viewport
          // to lay the page out, so it sits behind the (opaque) tabs.
          if (supportsInAppWebView)
            Positioned(
              left: 0,
              top: 0,
              width: 400,
              height: 900,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.01,
                  child: WebViewWidget(
                    controller: LiveCatalogService.instance.controller,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: IndexedStack(
                index: appState.tabIndex,
                children: [
                  const HomeTab(),
                  const ProductsTab(),
                  appState.selectedStore == null
                      ? const StoreSelectionScreen()
                      : const ShoppingScreen(),
                  const ProfileTab(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.tabIndex,
        onDestinationSelected: appState.setTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFC8E6C9),
        height: 68,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: appState.basketItemCount > 0,
              label: Text('${appState.basketItemCount}'),
              child: const Icon(Icons.shopping_basket_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: appState.basketItemCount > 0,
              label: Text('${appState.basketItemCount}'),
              child: const Icon(Icons.shopping_basket_rounded),
            ),
            label: 'Basket',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

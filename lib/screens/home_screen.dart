import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/store.dart';
import '../models/user.dart';
import 'auth_screen.dart';
import 'store_selection_screen.dart';
import 'shopping_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Show authentication screen if not logged in
        if (!appState.isAuthenticated) {
          return const AuthScreen();
        }

        // Show shopping screen if store is selected
        if (appState.selectedStore != null) {
          return const ShoppingScreen();
        }

        // Show store selection screen
        return const StoreSelectionScreen();
      },
    );
  }
}

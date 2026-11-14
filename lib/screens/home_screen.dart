import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'auth_screen.dart';
import 'location_permission_screen.dart';
import 'main_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (!appState.isAuthenticated) {
          return const AuthScreen();
        }

        // Still loading whether the location prompt was already shown.
        if (appState.locationPromptDone == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Ask for location once, right after signing up or in.
        if (!appState.locationPromptDone!) {
          return const LocationPermissionScreen();
        }

        return const MainShell();
      },
    );
  }
}

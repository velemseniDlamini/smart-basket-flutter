import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/store_web_view_screen.dart';

bool get supportsInAppWebView =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Opens a store's official page. On phones it opens inside the app so the
/// store's own photos and prices show without leaving Smart Basket; on web it
/// opens in a new browser tab.
Future<void> openExternal(
  BuildContext context,
  Uri url, {
  String title = 'Official website',
}) async {
  if (supportsInAppWebView) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoreWebViewScreen(url: url, title: title),
      ),
    );
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final opened = await launchUrl(url, mode: LaunchMode.platformDefault);
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not open ${url.host}')),
    );
  }
}

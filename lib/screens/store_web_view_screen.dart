import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Shows a store's official web page (live photos and prices) inside the app.
class StoreWebViewScreen extends StatefulWidget {
  final Uri url;
  final String title;

  const StoreWebViewScreen({super.key, required this.url, required this.title});

  @override
  State<StoreWebViewScreen> createState() => _StoreWebViewScreenState();
}

class _StoreWebViewScreenState extends State<StoreWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _failed = false;
  bool _retriedEmptyResults = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onPageStarted: (_) => setState(() => _failed = false),
          onPageFinished: (_) => _retryIfResultsDropped(),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) setState(() => _failed = true);
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  /// Shoprite's search page occasionally re-renders without the search term
  /// and shows no results. Reload once if the term is missing from the page.
  Future<void> _retryIfResultsDropped() async {
    final term = widget.url.queryParameters['Search'];
    if (term == null || term.isEmpty || _retriedEmptyResults) return;
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    try {
      final found = await _controller.runJavaScriptReturningResult(
        '(document.querySelector("main") || document.body).innerText'
        '.toLowerCase().includes(${_jsString(term.toLowerCase())})',
      );
      if (found == false || found == 'false' || found == 0) {
        _retriedEmptyResults = true;
        await _controller.loadRequest(widget.url);
      }
    } catch (_) {}
  }

  static String _jsString(String value) =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 17)),
            Text(
              widget.url.host,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE8F5E9)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller.reload,
          ),
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_browser_rounded),
            onPressed: () async {
              final current = await _controller.currentUrl();
              await launchUrl(
                current == null ? widget.url : Uri.parse(current),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ],
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFFFFB300),
                ),
              )
            : null,
      ),
      body: _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 56),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load the page. Check your connection.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _controller.reload,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}

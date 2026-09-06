import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'reader_bridge.dart';

/// Reusable WebView container hosting `assets/reader.html` and bound to `ReaderBridge`.
class ReaderWebView extends StatefulWidget {
  final ReaderBridge bridge;
  final VoidCallback? onWebViewCreated;

  const ReaderWebView({
    super.key,
    required this.bridge,
    this.onWebViewCreated,
  });

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FoliateChannel',
        onMessageReceived: (JavaScriptMessage message) {
          widget.bridge.handleMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            widget.bridge.checkReady();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('ReaderWebView Resource Error: ${error.description}');
          },
        ),
      );

    widget.bridge.attachController(_controller);
    _controller.loadFlutterAsset('assets/reader.html');
    widget.onWebViewCreated?.call();
  }

  @override
  void dispose() {
    widget.bridge.detachController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

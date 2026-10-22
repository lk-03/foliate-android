import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isPlatformSupported = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (WebViewPlatform.instance == null) {
      _isPlatformSupported = false;
      _isLoading = false;
      widget.bridge.onError?.call(
        'WebView is not available on this platform (${Platform.operatingSystem}).',
      );
      return;
    }

    try {
      final controller = WebViewController()
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

      _controller = controller;
      widget.bridge.attachController(controller);
      controller.loadFlutterAsset('assets/reader.html');
      widget.onWebViewCreated?.call();
    } catch (e) {
      _isPlatformSupported = false;
      _isLoading = false;
      debugPrint('ReaderWebView initialization error: $e');
      widget.bridge.onError?.call('WebView failed to initialize: $e');
    }
  }

  @override
  void dispose() {
    widget.bridge.detachController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPlatformSupported || _controller == null) {
      return const SizedBox.shrink();
    }

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(
            controller: _controller!,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

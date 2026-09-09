import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/reader_settings.dart';

enum PageTurnDirection { next, prev }

/// Two-tier page transition overlay supporting both:
/// 1. Stable 3D Flip (Perspective matrix, spine crease shadows, backside render)
/// 2. Experimental Peak Realism (GPU Fragment Shader shaders/page_curl.frag)
class PageCurlOverlay extends StatefulWidget {
  final Widget child;
  final ReaderSettings settings;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onNextPage;
  final VoidCallback onPrevPage;
  final VoidCallback onToggleHUD;
  final bool enabled;

  const PageCurlOverlay({
    super.key,
    required this.child,
    required this.settings,
    required this.backgroundColor,
    required this.textColor,
    required this.onNextPage,
    required this.onPrevPage,
    required this.onToggleHUD,
    this.enabled = true,
  });

  @override
  State<PageCurlOverlay> createState() => _PageCurlOverlayState();
}

class _PageCurlOverlayState extends State<PageCurlOverlay>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  late AnimationController _animController;

  PageTurnDirection? _turnDirection;
  double _dragProgress = 0.0;
  Offset _touchPosition = Offset.zero;
  Offset _dragStartPosition = Offset.zero;
  bool _isDragging = false;

  ui.FragmentProgram? _shaderProgram;
  ui.Image? _pageSnapshot;
  ui.Image? _blankNextImage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _animController.addListener(() {
      if (mounted && _isDragging) {
        setState(() {
          _dragProgress = _animController.value;
        });
      }
    });
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final direction = _turnDirection;
        _resetDrag();
        if (direction == PageTurnDirection.next) {
          widget.onNextPage();
        } else if (direction == PageTurnDirection.prev) {
          widget.onPrevPage();
        }
      } else if (status == AnimationStatus.dismissed) {
        _resetDrag();
      }
    });

    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      _shaderProgram =
          await ui.FragmentProgram.fromAsset('shaders/page_curl.frag');
      if (mounted) setState(() {});
    } catch (_) {
      // Graceful fallback to 3D matrix flip when shader compilation is unavailable
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageSnapshot?.dispose();
    _blankNextImage?.dispose();
    super.dispose();
  }

  void _resetDrag() {
    _isDragging = false;
    _turnDirection = null;
    _dragProgress = 0.0;
    _pageSnapshot?.dispose();
    _pageSnapshot = null;
    if (_animController.value != 0.0) {
      _animController.value = 0.0;
    }
  }

  Future<void> _captureSnapshot() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) return;
      final image = await boundary.toImage(pixelRatio: 1.5);
      if (mounted) {
        setState(() {
          _pageSnapshot = image;
        });
      }
    } catch (_) {
      // Fallback if repaint boundary capture is delayed
    }
  }

  Future<ui.Image> _getOrCreateBlankImage(Size size) async {
    if (_blankNextImage != null &&
        _blankNextImage!.width == size.width.toInt() &&
        _blankNextImage!.height == size.height.toInt()) {
      return _blankNextImage!;
    }
    _blankNextImage?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = widget.backgroundColor,
    );
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      math.max(1, size.width.toInt()),
      math.max(1, size.height.toInt()),
    );
    _blankNextImage = img;
    return img;
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled || _isDragging) return;
    final width = MediaQuery.of(context).size.width;
    final x = details.localPosition.dx;
    final ratio = x / width;

    if (ratio < 0.28) {
      _animatePageTurn(PageTurnDirection.prev);
    } else if (ratio > 0.72) {
      _animatePageTurn(PageTurnDirection.next);
    } else {
      widget.onToggleHUD();
    }
  }

  void _animatePageTurn(PageTurnDirection direction) {
    if (widget.settings.pageAnimationMode == PageAnimationMode.none ||
        widget.settings.pageAnimationMode == PageAnimationMode.scroll) {
      if (direction == PageTurnDirection.next) {
        widget.onNextPage();
      } else {
        widget.onPrevPage();
      }
      return;
    }

    _turnDirection = direction;
    _isDragging = true;
    _dragProgress = 0.0;
    _captureSnapshot();

    _animController.forward(from: 0.0);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!widget.enabled ||
        widget.settings.pageAnimationMode == PageAnimationMode.scroll) {
      return;
    }
    _dragStartPosition = details.localPosition;
    _touchPosition = details.localPosition;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled ||
        widget.settings.pageAnimationMode == PageAnimationMode.scroll) {
      return;
    }
    final width = MediaQuery.of(context).size.width;
    _touchPosition = details.localPosition;
    final deltaX = details.primaryDelta ?? 0.0;
    final totalDeltaX = details.localPosition.dx - _dragStartPosition.dx;

    if (!_isDragging) {
      if (totalDeltaX.abs() > 6.0) {
        _isDragging = true;
        _captureSnapshot();
        if (totalDeltaX < 0) {
          _turnDirection = PageTurnDirection.next;
        } else {
          _turnDirection = PageTurnDirection.prev;
        }
      } else {
        return;
      }
    }

    if (_turnDirection == PageTurnDirection.next) {
      _dragProgress = (_dragProgress - deltaX / width).clamp(0.0, 1.0);
    } else if (_turnDirection == PageTurnDirection.prev) {
      _dragProgress = (_dragProgress + deltaX / width).clamp(0.0, 1.0);
    }

    _animController.value = _dragProgress;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging ||
        widget.settings.pageAnimationMode == PageAnimationMode.scroll) {
      _resetDrag();
      return;
    }
    final velocity = details.primaryVelocity ?? 0.0;
    final shouldTurn = _dragProgress > 0.28 ||
        (_turnDirection == PageTurnDirection.next && velocity < -300) ||
        (_turnDirection == PageTurnDirection.prev && velocity > 300);

    if (shouldTurn) {
      _animController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      _animController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.settings.pageAnimationMode;
    final isAnimating = _isDragging && _dragProgress > 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Live Underlying Content wrapped in RepaintBoundary for high-FPS snapshots
        RepaintBoundary(
          key: _repaintBoundaryKey,
          child: widget.child,
        ),

        // Animated Page Turn Transition Overlay
        if (isAnimating &&
            mode == PageAnimationMode.curlShader &&
            _shaderProgram != null &&
            _pageSnapshot != null)
          Positioned.fill(
            child: FutureBuilder<ui.Image>(
              future: _getOrCreateBlankImage(MediaQuery.of(context).size),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _build3DMatrixFlip(context);
                }
                return CustomPaint(
                  painter: _GLSLPageCurlPainter(
                    shader: _shaderProgram!.fragmentShader(),
                    currentPage: _pageSnapshot!,
                    nextPage: snapshot.data!,
                    progress: _dragProgress,
                    touch: _touchPosition,
                    direction: _turnDirection ?? PageTurnDirection.next,
                  ),
                );
              },
            ),
          )
        else if (isAnimating &&
            (mode == PageAnimationMode.curl ||
                mode == PageAnimationMode.curlShader))
          Positioned.fill(
            child: _build3DMatrixFlip(context),
          )
        else if (isAnimating && mode == PageAnimationMode.slide)
          Positioned.fill(
            child: _buildSlideTransition(context),
          ),

        // Gesture Detection Overlay
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: _onTapUp,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
          ),
        ),
      ],
    );
  }

  /// Tier 1: Stable 3D Perspective Matrix Page Flip
  Widget _build3DMatrixFlip(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isNext =
        (_turnDirection ?? PageTurnDirection.next) == PageTurnDirection.next;
    final flipAngle = (isNext ? -math.pi : math.pi) * _dragProgress;
    final isFlippedPastHalf = _dragProgress > 0.5;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Underneath Page Background Reveal
        Container(color: widget.backgroundColor),

        // 3D Flipping Page Quad
        Transform(
          alignment: isNext ? Alignment.centerLeft : Alignment.centerRight,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(flipAngle),
          child: isFlippedPastHalf
              ? _buildBacksidePage(size, isNext)
              : _buildFrontsidePage(size, isNext),
        ),

        // Spine Crease Shadow
        Positioned(
          left: isNext ? 0 : null,
          right: isNext ? null : 0,
          top: 0,
          bottom: 0,
          width: 32,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isNext ? Alignment.centerLeft : Alignment.centerRight,
                  end: isNext ? Alignment.centerRight : Alignment.centerLeft,
                  colors: [
                    Colors.black
                        .withValues(alpha: 0.28 * (1.0 - _dragProgress)),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrontsidePage(Size size, bool isNext) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: widget.backgroundColor,
          child: _pageSnapshot != null
              ? RawImage(
                  image: _pageSnapshot,
                  fit: BoxFit.fill,
                  width: size.width,
                  height: size.height,
                )
              : null,
        ),
        // Dynamic Curl Shadow on Front
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isNext ? Alignment.centerRight : Alignment.centerLeft,
              end: isNext ? Alignment.centerLeft : Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.35 * _dragProgress),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBacksidePage(Size size, bool isNext) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: widget.backgroundColor,
            child: _pageSnapshot != null
                ? Opacity(
                    opacity: 0.18,
                    child: RawImage(
                      image: _pageSnapshot,
                      fit: BoxFit.fill,
                      width: size.width,
                      height: size.height,
                    ),
                  )
                : null,
          ),
          // Back-of-page specular paper sheen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isNext ? Alignment.centerLeft : Alignment.centerRight,
                end: isNext ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.25 * (1.0 - _dragProgress)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Slide Transition Overlay
  Widget _buildSlideTransition(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNext =
        (_turnDirection ?? PageTurnDirection.next) == PageTurnDirection.next;
    final offset = (isNext ? -width : width) * _dragProgress;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: widget.backgroundColor),
        Transform.translate(
          offset: Offset(offset, 0),
          child: Container(
            color: widget.backgroundColor,
            child: _pageSnapshot != null
                ? RawImage(
                    image: _pageSnapshot,
                    fit: BoxFit.fill,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Tier 2: GLSL Fragment Shader CustomPainter
class _GLSLPageCurlPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image currentPage;
  final ui.Image nextPage;
  final double progress;
  final Offset touch;
  final PageTurnDirection direction;

  _GLSLPageCurlPainter({
    required this.shader,
    required this.currentPage,
    required this.nextPage,
    required this.progress,
    required this.touch,
    required this.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Uniform 0, 1: uResolution (vec2)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // Uniform 2: uProgress (float)
    shader.setFloat(2, progress);

    // Uniform 3, 4: uTouch (vec2)
    final touchX = touch.dx == 0 ? size.width * (1.0 - progress) : touch.dx;
    final touchY = touch.dy == 0 ? size.height * 0.5 : touch.dy;
    shader.setFloat(3, touchX);
    shader.setFloat(4, touchY);

    // Uniform 5: uRadius (float)
    shader.setFloat(5, 0.14);

    // Uniform 6: uAngle (float)
    final verticalDelta = (touchY - size.height * 0.5) / size.height;
    final angle =
        (direction == PageTurnDirection.next ? -0.12 : 0.12) * verticalDelta;
    shader.setFloat(6, angle);

    // Sampler 0: uCurrentPage
    shader.setImageSampler(0, currentPage);

    // Sampler 1: uNextPage
    shader.setImageSampler(1, nextPage);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _GLSLPageCurlPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.touch != touch ||
        oldDelegate.currentPage != currentPage ||
        oldDelegate.nextPage != nextPage;
  }
}

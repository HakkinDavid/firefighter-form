import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bomberos/models/settings.dart';

// Handles entry and disposal of the overlay
class OverlayService {
  static OverlayEntry? _currentOverlayEntry;

  static void showOverlay({
    required Offset position,
    required Size buttonSize,
    required Widget overlayContent,
    // Default values subject to change, of course
    double overlayWidth = 200,
    double overlayPadding = 5,
    double borderRadius = 4,
    bool tapToClose = true,
    bool isBottomAnchored = false,
  }) {
    // Close existing overlay if open
    closeCurrentOverlay();

    final overlayState = Settings.instance.navigatorKey.currentState?.overlay;

    _currentOverlayEntry = OverlayEntry(
      builder: (context) => OverlayObject(
        position: position,
        buttonSize: buttonSize,
        overlayContent: overlayContent,
        overlayWidth: overlayWidth,
        overlayPadding: overlayPadding,
        borderRadius: borderRadius,
        tapToClose: tapToClose,
        isBottomAnchored: isBottomAnchored,
        onClose: closeCurrentOverlay,
      ),
    );

    overlayState?.insert(_currentOverlayEntry!);
  }

  static void closeCurrentOverlay() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }
}

class OverlayObject extends StatefulWidget {
  final Offset position;
  final Size buttonSize;
  final Widget overlayContent;
  final double overlayWidth;
  final double overlayPadding;
  final double borderRadius;
  final bool tapToClose;
  final bool isBottomAnchored;
  final VoidCallback onClose;
  const OverlayObject({
    super.key,
    required this.position,
    required this.buttonSize,
    required this.overlayContent,
    required this.overlayWidth,
    required this.overlayPadding,
    required this.borderRadius,
    required this.tapToClose,
    required this.isBottomAnchored,
    required this.onClose
  });

  @override
  State<OverlayObject> createState() => _OverlayObjectState();
}

class _OverlayObjectState extends State<OverlayObject> {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SafeArea(
      child: Stack(
        children: [
          // Background tap to close
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.tapToClose
                  ? widget.onClose
                  : null,
              child: Container(color: CupertinoColors.transparent),
            ),
          ),
          widget.isBottomAnchored
              ? Positioned(
                  left: (MediaQuery.of(context).size.width - widget.overlayWidth) / 2,
                  bottom: 16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    color: CupertinoColors.darkBackgroundGray.withValues(alpha: 0.8),
                    child: Container(
                      width: widget.overlayWidth,
                      padding: EdgeInsets.all(widget.overlayPadding),
                      child: widget.overlayContent,
                    ),
                  ),
                )
              : Positioned(
                  left: widget.position.dx - (widget.overlayWidth - widget.buttonSize.width) / 2,
                  top: widget.position.dy > topPadding
                      ? widget.position.dy - topPadding + 10
                      : widget.position.dy + 10,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    color: CupertinoColors.darkBackgroundGray.withValues(alpha: 0.8),
                    child: Container(
                      width: widget.overlayWidth,
                      padding: EdgeInsets.all(widget.overlayPadding),
                      child: widget.overlayContent,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
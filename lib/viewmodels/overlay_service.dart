import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Handles entry and disposal of the overlay
class OverlayService {
  static OverlayEntry? _currentOverlayEntry;

  static void showOverlay({
    required BuildContext context,
    required Offset position,
    required Size buttonSize,
    required Widget overlayContent,
    // Default values subject to change, of course
    double overlayWidth = 200,
    double overlayPadding = 5,
    double borderRadius = 4,
    bool tapToClose = true,
  }) {
    // Close existing overlay if open
    closeCurrentOverlay();

    final overlayState = Overlay.of(context);

    _currentOverlayEntry = OverlayEntry(
      builder: (context) => OverlayObject(
        position: position,
        buttonSize: buttonSize,
        overlayContent: overlayContent,
        overlayWidth: overlayWidth,
        overlayPadding: overlayPadding,
        borderRadius: borderRadius,
        tapToClose: tapToClose,
        onClose: closeCurrentOverlay,
      ),
    );

    overlayState.insert(_currentOverlayEntry!);
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
    required this.onClose
  });

  @override
  State<OverlayObject> createState() => _OverlayObjectState();
}

class _OverlayObjectState extends State<OverlayObject> {
  @override
  Widget build(BuildContext context) {
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
          Positioned(
            left: widget.position.dx - (widget.overlayWidth - widget.buttonSize.width)/2,
            top: widget.position.dy + 10,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              // New ColorSettings, perhaps?
              color: CupertinoColors.darkBackgroundGray.withValues(alpha: 0.8),
              child: Container(
                width: widget.overlayWidth,
                padding: EdgeInsets.all(widget.overlayPadding),
                // Render widget
                child: widget.overlayContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
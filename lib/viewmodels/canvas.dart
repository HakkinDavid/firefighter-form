import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Modelo para un punto en el trazo.
class StrokePoint {
  final Offset point;
  StrokePoint(this.point);
}

/// Modelo para un trazo, que es una lista de puntos.
class Stroke {
  final List<Offset> points;
  Stroke(this.points);
}

/// Controller para controlar el canvas externamente, manteniendo trazos previos y nuevos en coordenadas absolutas.
class ServiceCanvasController extends ChangeNotifier {
  final int viewBoxWidth;
  final int viewBoxHeight;

  List<Stroke> _previousStrokes = [];
  List<Stroke> _currentStrokes = [];

  ServiceCanvasController({this.viewBoxWidth = 300, this.viewBoxHeight = 300});

  /// Establece los trazos previos a partir de SVG base64 absoluto.
  /// Analiza el SVG para extraer los trazos en coordenadas absolutas.
  /// En esta implementación simplificada, se asume que los trazos previos son paths simples.
  /// Para un análisis completo se requeriría un parser SVG más avanzado.
  void setDefaultData(String? data) {
    _previousStrokes.clear();
    if (data != null && data.isNotEmpty) {
      final svgString = utf8.decode(
        base64Decode(
          data.replaceAll(RegExp(r'data:image/svg\+xml;base64,'), ''),
        ),
      );
      // Parsear el SVG y extraer los paths <path d="...">
      final pathRegex = RegExp(r'<path[^>]*d="([^"]+)"', multiLine: true, caseSensitive: false);
      final matches = pathRegex.allMatches(svgString);
      for (final match in matches) {
        final d = match.group(1);
        if (d == null) continue;
        // Parsear comandos M y L básicos
        final cmds = RegExp(r'([ML])\s*([-\d\.]+)[ ,]+([-\d\.]+)', caseSensitive: false).allMatches(d);
        List<Offset> points = [];
        for (final cmd in cmds) {
          // cmd.group(1): 'M' o 'L'
          final x = double.tryParse(cmd.group(2)!);
          final y = double.tryParse(cmd.group(3)!);
          if (x != null && y != null) {
            points.add(Offset(x, y));
          }
        }
        if (points.isNotEmpty) {
          _previousStrokes.add(Stroke(points));
        }
      }
      // Guardar el SVG para exportación
      _setPreviousSvgData(data);
    }
    notifyListeners();
  }

  /// Obtiene los trazos previos (no usados para dibujo, solo referencia).
  List<Stroke> get previousStrokes => List.unmodifiable(_previousStrokes);

  /// Obtiene los trazos actuales (nuevos).
  List<Stroke> get currentStrokes => List.unmodifiable(_currentStrokes);

  /// Añade un punto al trazo actual.
  void addPointToCurrentStroke(Offset point) {
    if (_currentStrokes.isEmpty) {
      _currentStrokes.add(Stroke([point]));
    } else {
      _currentStrokes.last.points.add(point);
    }
    notifyListeners();
  }

  /// Inicia un nuevo trazo.
  void startNewStroke(Offset point) {
    _currentStrokes.add(Stroke([point]));
    notifyListeners();
  }

  /// Finaliza el trazo actual.
  void endCurrentStroke() {
    notifyListeners();
  }

  /// Limpia todo: trazos previos y nuevos.
  void clear() {
    _previousStrokes.clear();
    _currentStrokes.clear();
    notifyListeners();
  }

  /// Limpia sólo los trazos nuevos.
  void clearCurrentStrokes() {
    _currentStrokes.clear();
    notifyListeners();
  }

  /// Exporta el contenido combinado de trazos previos y nuevos como SVG en base64.
  /// Los trazos nuevos se agregan a los previos y se limpian.
  Future<String> exportAsSvg() async {
    // Construir paths SVG para los trazos nuevos
    String strokesToSvgPaths(List<Stroke> strokes) {
      final buffer = StringBuffer();
      for (final stroke in strokes) {
        if (stroke.points.isEmpty) continue;
        buffer.write('<path d="M');
        for (int i = 0; i < stroke.points.length; i++) {
          final p = stroke.points[i];
          buffer.write('${p.dx.toStringAsFixed(2)} ${p.dy.toStringAsFixed(2)}');
          if (i != stroke.points.length - 1) {
            buffer.write(' L');
          }
        }
        buffer.write('" stroke="black" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>');
      }
      return buffer.toString();
    }

    // Extraer contenido interno de SVG previo para combinar
    String? prevSvgContent;
    if (_previousSvgData != null && _previousSvgData!.isNotEmpty) {
      final svgString = utf8.decode(
        base64Decode(
          _previousSvgData!.replaceAll(RegExp(r'data:image/svg\+xml;base64,'), ''),
        ),
      );
      final start = svgString.indexOf('>') + 1;
      final end = svgString.lastIndexOf('</svg>');
      if (start >= 0 && end >= 0 && end > start) {
        prevSvgContent = svgString.substring(start, end).trim();
      } else {
        prevSvgContent = svgString;
      }
    }

    // Construir SVG combinado
    final viewBox = '0 0 $viewBoxWidth $viewBoxHeight';
    final newPaths = strokesToSvgPaths(_currentStrokes);

    final combinedSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox" preserveAspectRatio="xMidYMid meet" width="$viewBoxWidth" height="$viewBoxHeight">
  <g id="previous_strokes">${prevSvgContent ?? ''}</g>
  <g id="new_strokes">
    $newPaths
  </g>
</svg>
''';

    final base64Svg = base64Encode(utf8.encode(combinedSvg));
    final dataUri = "data:image/svg+xml;base64,$base64Svg";

    // Actualizar previos con el SVG combinado
    _previousSvgData = dataUri;
    _previousStrokes.addAll(_currentStrokes);
    _currentStrokes.clear();
    notifyListeners();

    return dataUri;
  }

  String? _previousSvgData;

  /// Establece el SVG previo directamente (para uso interno).
  void _setPreviousSvgData(String? data) {
    _previousSvgData = data;
  }

  bool get isEmpty {
    return _previousStrokes.isEmpty && _currentStrokes.isEmpty;
  }

  /// Obtiene el SVG previo almacenado.
  String? get previousSvgData => _previousSvgData;
}

/// Widget para dibujar o firmar sobre un fondo, con control externo y capas separadas,
/// usando un viewBox absoluto fijo para mantener la escala y posición exacta.
class ServiceCanvas extends StatefulWidget {
  final String? defaultData; // SVG base64 de trazos previos (coordenadas absolutas)
  final String? backgroundData; // Fondo SVG base64 absoluto (inmodificable)
  final ServiceCanvasController controller;
  final bool disabled;
  final double viewBoxWidth;
  final double viewBoxHeight;

  const ServiceCanvas({
    super.key,
    this.defaultData,
    this.backgroundData,
    required this.controller,
    this.disabled = false,
    this.viewBoxWidth = 300,
    this.viewBoxHeight = 300,
  });

  @override
  State<ServiceCanvas> createState() => _ServiceCanvasState();
}

class _ServiceCanvasState extends State<ServiceCanvas> {
  late double scale;
  late Offset offset;

  @override
  void initState() {
    super.initState();

    widget.controller.setDefaultData(widget.defaultData);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ServiceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      widget.controller.setDefaultData(widget.defaultData);
    } else if (widget.defaultData != oldWidget.defaultData) {
      widget.controller.setDefaultData(widget.defaultData);
    }
  }

  void _onControllerChanged() {
    setState(() {
      // Actualizar UI cuando cambian datos en el controller
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  Offset _globalToLocal(Offset globalPosition, RenderBox renderBox) {
    final local = renderBox.globalToLocal(globalPosition);
    final size = renderBox.size;

    // Mapear local (en tamaño renderizado) a coordenadas absolutas en viewBox
    final dx = (local.dx / size.width) * widget.viewBoxWidth;
    final dy = (local.dy / size.height) * widget.viewBoxHeight;

    return Offset(dx.clamp(0, widget.viewBoxWidth), dy.clamp(0, widget.viewBoxHeight));
  }

  @override
  Widget build(BuildContext context) {
    // El AspectRatio se fija a la relación del viewBox para mantener escala absoluta
    final aspectRatio = widget.viewBoxWidth / widget.viewBoxHeight;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          border: Border.all(color: CupertinoColors.separator),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calcular escala para que el canvas use coordenadas absolutas del viewBox
            final scaleX = constraints.maxWidth / widget.viewBoxWidth;
            final scaleY = constraints.maxHeight / widget.viewBoxHeight;
            scale = scaleX < scaleY ? scaleX : scaleY;

            final canvasWidth = widget.viewBoxWidth * scale;
            final canvasHeight = widget.viewBoxHeight * scale;

            // Calcular offset para centrar el canvas dentro del espacio disponible
            final dx = (constraints.maxWidth - canvasWidth) / 2;
            final dy = (constraints.maxHeight - canvasHeight) / 2;
            offset = Offset(dx, dy);

            return Stack(
              children: [
                Positioned(
                  left: dx,
                  top: dy,
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Stack(
                    children: [
                      // Fondo SVG
                      if (widget.backgroundData != null && widget.backgroundData!.isNotEmpty)
                        SvgPicture.string(
                          utf8.decode(
                            base64Decode(
                              widget.backgroundData!.replaceAll(
                                RegExp(r'data:image/svg\+xml;base64,'),
                                '',
                              ),
                            ),
                          ),
                          fit: BoxFit.fill,
                          width: canvasWidth,
                          height: canvasHeight,
                        ),
                      // Trazos previos dibujados sobre el fondo usando SVG guardado en controller
                      if (widget.controller.previousSvgData != null && widget.controller.previousSvgData!.isNotEmpty)
                        SvgPicture.string(
                          utf8.decode(
                            base64Decode(
                              widget.controller.previousSvgData!.replaceAll(
                                RegExp(r'data:image/svg\+xml;base64,'),
                                '',
                              ),
                            ),
                          ),
                          fit: BoxFit.fill,
                          width: canvasWidth,
                          height: canvasHeight,
                        ),
                      // Trazos nuevos dibujados con CustomPainter y todos los eventos de puntero absorbidos para evitar scroll/gestos del parent
                      Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (_) {},
                        onPointerMove: (_) {},
                        onPointerUp: (_) {},
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: widget.disabled
                              ? null
                              : (details) {
                                  final renderBox = context.findRenderObject() as RenderBox;
                                  final localPos = _globalToLocal(details.globalPosition, renderBox);
                                  widget.controller.startNewStroke(localPos);
                                },
                          onPanUpdate: widget.disabled
                              ? null
                              : (details) {
                                  final renderBox = context.findRenderObject() as RenderBox;
                                  final localPos = _globalToLocal(details.globalPosition, renderBox);
                                  widget.controller.addPointToCurrentStroke(localPos);
                                },
                          onPanEnd: widget.disabled
                              ? null
                              : (details) {
                                  widget.controller.endCurrentStroke();
                                },
                          child: SizedBox(
                            width: canvasWidth,
                            height: canvasHeight,
                            child: CustomPaint(
                              size: Size(canvasWidth, canvasHeight),
                              painter: _CanvasPainter(
                                scale: scale,
                                currentStrokes: widget.controller.currentStrokes,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final double scale;
  final List<Stroke> currentStrokes;

  _CanvasPainter({
    required this.scale,
    required this.currentStrokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // No dibujamos los trazos previos aquí porque se muestran como SVG debajo.
    // Sólo dibujamos los trazos nuevos escalados.

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in currentStrokes) {
      if (stroke.points.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.points[0].dx * scale, stroke.points[0].dy * scale);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx * scale, stroke.points[i].dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return oldDelegate.currentStrokes != currentStrokes || oldDelegate.scale != scale;
  }
}

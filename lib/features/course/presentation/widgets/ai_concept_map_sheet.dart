import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../bloc/ai_assistant_event.dart';
import '../bloc/ai_assistant_state.dart';
import '../../../../core/theme/app_colors.dart';

class AiConceptMapSheet extends StatefulWidget {
  final String lessonTitle;
  final String textContent;

  const AiConceptMapSheet({
    super.key,
    required this.lessonTitle,
    required this.textContent,
  });

  @override
  State<AiConceptMapSheet> createState() => _AiConceptMapSheetState();
}

class _AiConceptMapSheetState extends State<AiConceptMapSheet> {
  String? _selectedNodeId;

  @override
  void initState() {
    super.initState();
    final state = context.read<AiAssistantBloc>().state;
    if (state is! AiConceptMapLoaded && state is! AiConceptMapLoading) {
      context.read<AiAssistantBloc>().add(
        GenerateConceptMap(
          lessonTitle: widget.lessonTitle,
          textContent: widget.textContent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(cs),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<AiAssistantBloc, AiAssistantState>(
                  builder: (context, state) {
                    if (state is AiConceptMapLoading) {
                      return _buildLoading(cs);
                    }
                    if (state is AiConceptMapLoaded) {
                      return _buildMap(context, state, cs);
                    }
                    if (state is AiError) {
                      return _buildError(context, state, cs);
                    }
                    return _buildLoading(cs);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bản đồ khái niệm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Được tạo tự động bởi AI',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoading(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Đang phân tích và tạo bản đồ khái niệm...',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Quá trình này có thể mất 10-20 giây',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, AiError state, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                context.read<AiAssistantBloc>().add(
                  GenerateConceptMap(
                    lessonTitle: widget.lessonTitle,
                    textContent: widget.textContent,
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    AiConceptMapLoaded state,
    ColorScheme cs,
  ) {
    final positions = _calculatePositions(state.nodes, state.edges);
    final selectedNode = _selectedNodeId != null
        ? state.nodes.where((n) => n.id == _selectedNodeId).firstOrNull
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildLegendChip('Chính', _coreColor(cs)),
              const SizedBox(width: 8),
              _buildLegendChip('Phụ', _subColor(cs)),
              const SizedBox(width: 8),
              _buildLegendChip('Ví dụ', _exampleColor(cs)),
              const Spacer(),
              Text(
                '${state.nodes.length} khái niệm',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.3,
            maxScale: 3.0,
            child: SizedBox(
              width: 800,
              height: 700,
              child: GestureDetector(
                onTapDown: (details) {
                  _handleTap(details.localPosition, state.nodes, positions);
                },
                child: CustomPaint(
                  size: const Size(800, 700),
                  painter: _ConceptMapPainter(
                    nodes: state.nodes,
                    edges: state.edges,
                    positions: positions,
                    selectedId: _selectedNodeId,
                    cs: cs,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (selectedNode != null) _buildNodeDetail(selectedNode, cs),
      ],
    );
  }

  Widget _buildLegendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildNodeDetail(ConceptNode node, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _colorForType(node.type, cs).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  node.type == 'core' ? 'Khái niệm chính' : node.type == 'example' ? 'Ví dụ' : 'Khái niệm phụ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _colorForType(node.type, cs),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                onPressed: () => setState(() => _selectedNodeId = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            node.description,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(
    Offset position,
    List<ConceptNode> nodes,
    Map<String, Offset> positions,
  ) {
    for (final node in nodes) {
      final pos = positions[node.id];
      if (pos == null) continue;
      final nodeRect = Rect.fromCenter(
        center: pos,
        width: _nodeWidth(node),
        height: 44,
      );
      if (nodeRect.contains(position)) {
        setState(() {
          _selectedNodeId = _selectedNodeId == node.id ? null : node.id;
        });
        return;
      }
    }
    setState(() => _selectedNodeId = null);
  }

  double _nodeWidth(ConceptNode node) {
    return (node.label.length * 9.0 + 32).clamp(80.0, 200.0);
  }

  Map<String, Offset> _calculatePositions(
    List<ConceptNode> nodes,
    List<ConceptEdge> edges,
  ) {
    if (nodes.isEmpty) return {};

    final positions = <String, Offset>{};
    final coreNodes = nodes.where((n) => n.type == 'core').toList();
    final subNodes = nodes.where((n) => n.type == 'sub').toList();
    final exampleNodes = nodes.where((n) => n.type == 'example').toList();

    const centerX = 400.0;
    const centerY = 350.0;

    if (coreNodes.length == 1) {
      positions[coreNodes[0].id] = const Offset(centerX, centerY);
    } else {
      for (var i = 0; i < coreNodes.length; i++) {
        final angle = (2 * pi * i / coreNodes.length) - pi / 2;
        positions[coreNodes[i].id] = Offset(
          centerX + 120 * cos(angle),
          centerY + 100 * sin(angle),
        );
      }
    }

    for (var i = 0; i < subNodes.length; i++) {
      final angle = (2 * pi * i / subNodes.length) - pi / 4;
      positions[subNodes[i].id] = Offset(
        centerX + 260 * cos(angle),
        centerY + 220 * sin(angle),
      );
    }

    for (var i = 0; i < exampleNodes.length; i++) {
      final parentEdge = edges.where((e) => e.to == exampleNodes[i].id).firstOrNull;
      if (parentEdge != null && positions.containsKey(parentEdge.from)) {
        final parentPos = positions[parentEdge.from]!;
        final angle = (2 * pi * i / max(exampleNodes.length, 1)) + pi / 6;
        positions[exampleNodes[i].id] = Offset(
          parentPos.dx + 140 * cos(angle),
          parentPos.dy + 120 * sin(angle),
        );
      } else {
        final angle = (2 * pi * i / max(exampleNodes.length, 1)) + pi / 3;
        positions[exampleNodes[i].id] = Offset(
          centerX + 340 * cos(angle),
          centerY + 280 * sin(angle),
        );
      }
    }

    for (final node in nodes) {
      if (!positions.containsKey(node.id)) {
        positions[node.id] = Offset(
          centerX + Random().nextDouble() * 300 - 150,
          centerY + Random().nextDouble() * 300 - 150,
        );
      }
    }

    return positions;
  }

  Color _coreColor(ColorScheme cs) => AppColors.primary;
  Color _subColor(ColorScheme cs) => AppColors.secondary;
  Color _exampleColor(ColorScheme cs) => AppColors.accent;

  Color _colorForType(String type, ColorScheme cs) {
    switch (type) {
      case 'core':
        return _coreColor(cs);
      case 'example':
        return _exampleColor(cs);
      default:
        return _subColor(cs);
    }
  }
}

class _ConceptMapPainter extends CustomPainter {
  final List<ConceptNode> nodes;
  final List<ConceptEdge> edges;
  final Map<String, Offset> positions;
  final String? selectedId;
  final ColorScheme cs;

  _ConceptMapPainter({
    required this.nodes,
    required this.edges,
    required this.positions,
    required this.selectedId,
    required this.cs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas);
    _drawNodes(canvas);
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in edges) {
      final from = positions[edge.from];
      final to = positions[edge.to];
      if (from == null || to == null) continue;

      final paint = Paint()
        ..color = cs.outlineVariant.withValues(alpha: 0.6)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      final midX = (from.dx + to.dx) / 2;
      final midY = (from.dy + to.dy) / 2;
      final controlOffset = (from.dx - to.dx).abs() > (from.dy - to.dy).abs()
          ? Offset(midX, midY - 30)
          : Offset(midX - 30, midY);

      path.moveTo(from.dx, from.dy);
      path.quadraticBezierTo(controlOffset.dx, controlOffset.dy, to.dx, to.dy);
      canvas.drawPath(path, paint);

      final angle = atan2(to.dy - controlOffset.dy, to.dx - controlOffset.dx);
      final arrowSize = 8.0;
      final arrowP1 = Offset(
        to.dx - arrowSize * cos(angle - 0.4),
        to.dy - arrowSize * sin(angle - 0.4),
      );
      final arrowP2 = Offset(
        to.dx - arrowSize * cos(angle + 0.4),
        to.dy - arrowSize * sin(angle + 0.4),
      );
      final arrowPath = Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(arrowP1.dx, arrowP1.dy)
        ..lineTo(arrowP2.dx, arrowP2.dy)
        ..close();
      canvas.drawPath(
        arrowPath,
        Paint()..color = cs.outlineVariant.withValues(alpha: 0.6),
      );

      if (edge.label.isNotEmpty) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: edge.label,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 120);

        final labelBg = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(midX, midY - 8),
            width: labelPainter.width + 8,
            height: labelPainter.height + 4,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(labelBg, Paint()..color = cs.surface.withValues(alpha: 0.9));

        labelPainter.paint(
          canvas,
          Offset(midX - labelPainter.width / 2, midY - 8 - labelPainter.height / 2),
        );
      }
    }
  }

  void _drawNodes(Canvas canvas) {
    for (final node in nodes) {
      final pos = positions[node.id];
      if (pos == null) continue;

      final color = _colorForType(node.type);
      final isSelected = node.id == selectedId;
      final width = (node.label.length * 9.0 + 32).clamp(80.0, 200.0);
      const height = 44.0;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: width, height: height),
        const Radius.circular(12),
      );

      if (isSelected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: pos, width: width + 6, height: height + 6),
            const Radius.circular(14),
          ),
          Paint()..color = color.withValues(alpha: 0.3),
        );
      }

      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: node.type == 'core' ? 0.15 : 0.08)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: isSelected ? 1.0 : 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.5 : 1.5,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: TextStyle(
            fontSize: node.type == 'core' ? 13 : 12,
            fontWeight: node.type == 'core' ? FontWeight.w700 : FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '...',
      )..layout(maxWidth: width - 16);

      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'core':
        return AppColors.primary;
      case 'example':
        return AppColors.accent;
      default:
        return AppColors.secondary;
    }
  }

  @override
  bool shouldRepaint(covariant _ConceptMapPainter oldDelegate) {
    return oldDelegate.selectedId != selectedId ||
        oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges;
  }
}

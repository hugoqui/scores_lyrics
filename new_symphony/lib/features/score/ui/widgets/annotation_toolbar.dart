import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/features/score/providers/annotation_provider.dart';

class AnnotationToolbar extends ConsumerWidget {
  final String noteKey;

  const AnnotationToolbar({super.key, required this.noteKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(annotationProvider(noteKey));
    final notifier = ref.read(annotationProvider(noteKey).notifier);
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 4,
      // Color semitransparente para que no tape totalmente la partitura
      color: Colors.white.withOpacity(0.9),
      child: Container(
        constraints: isLandscape
            ? BoxConstraints(maxHeight: screenHeight * 0.8, maxWidth: 110)
            : null,
        padding: isLandscape
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: SingleChildScrollView(
          // Permite scroll si hay demasiados elementos en pantallas muy pequeñas
          scrollDirection: isLandscape ? Axis.vertical : Axis.horizontal,
          child: _buildLayout(context, state, notifier, isLandscape),
        ),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    AnnotationState state,
    AnnotationNotifier notifier,
    bool isLandscape,
  ) {
    final groupA = _buildGroupA(context, state, notifier, isLandscape);
    final groupB = _buildGroupB(context, state, notifier, isLandscape);

    if (!state.isDrawingMode) {
      // Si no estamos dibujando, solo mostramos el grupo A en una sola línea
      return isLandscape
          ? Column(mainAxisSize: MainAxisSize.min, children: groupA)
          : Row(mainAxisSize: MainAxisSize.min, children: groupA);
    }

    // Si estamos dibujando, aplicamos la lógica de dos bloques (filas o columnas)
    if (isLandscape) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(mainAxisSize: MainAxisSize.min, children: groupA),
          const SizedBox(width: 4),
          Column(mainAxisSize: MainAxisSize.min, children: groupB),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: groupA),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: groupB),
        ],
      );
    }
  }

  Widget _getSpacer(bool isVertical) {
    return isVertical
        ? const SizedBox(height: 8, width: 24, child: Divider(height: 1))
        : const SizedBox(width: 8, height: 24, child: VerticalDivider(width: 1));
  }

  /// Grupo A: Acciones principales (Cerrar, Confirmar) y Herramientas de Formas
  List<Widget> _buildGroupA(
    BuildContext context,
    AnnotationState state,
    AnnotationNotifier notifier,
    bool isVertical
  ) {
    final spacer = _getSpacer(isVertical);

    if (!state.isDrawingMode) {
      return [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          color: Colors.grey,
          onPressed: notifier.toggleDrawingMode,
          tooltip: 'Modo dibujo',
        ),
        spacer,
        IconButton(
          icon: Icon(state.isVisible ? Icons.visibility : Icons.visibility_off),
          color: AppColors.accent,
          onPressed: notifier.toggleVisibility,
          tooltip: 'Ver/Ocultar notas',
        ),
      ];
    }

    return [
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.error),
          onPressed: notifier.cancelChanges,
          tooltip: 'Cancelar cambios',
        ),
        IconButton(
          icon: const Icon(Icons.check),
          color: AppColors.accent,
          onPressed: notifier.confirmChanges,
          tooltip: 'Confirmar notas',
        ),
        spacer,
        IconButton(
          icon: const Icon(Icons.gesture),
          color: state.activeTool == AnnotationTool.pencil ? AppColors.accent : Colors.grey,
          onPressed: () => notifier.setTool(AnnotationTool.pencil),
          tooltip: 'Lápiz',
        ),
        IconButton(
          icon: const Icon(Icons.trending_flat),
          color: state.activeTool == AnnotationTool.arrow ? AppColors.accent : Colors.grey,
          onPressed: () => notifier.setTool(AnnotationTool.arrow),
        ),
        IconButton(
          icon: const Icon(Icons.panorama_fish_eye),
          color: state.activeTool == AnnotationTool.circle ? AppColors.accent : Colors.grey,
          onPressed: () => notifier.setTool(AnnotationTool.circle),
        ),
        IconButton(
          icon: const Icon(Icons.crop_square),
          color: state.activeTool == AnnotationTool.square ? AppColors.accent : Colors.grey,
          onPressed: () => notifier.setTool(AnnotationTool.square),
        ),
    ];
  }

  /// Grupo B: Bloque de Colores y Borrado total
  List<Widget> _buildGroupB(
    BuildContext context,
    AnnotationState state,
    AnnotationNotifier notifier,
    bool isVertical
  ) {
    if (!state.isDrawingMode) return [];
    final spacer = _getSpacer(isVertical);

    return [
      _ColorButton(color: 0xFFFF0000, isSelected: state.selectedColor == 0xFFFF0000, onTap: () => notifier.setColor(0xFFFF0000)),
      _ColorButton(color: 0xFF0000FF, isSelected: state.selectedColor == 0xFF0000FF, onTap: () => notifier.setColor(0xFF0000FF)),
      _ColorButton(color: 0xFF000000, isSelected: state.selectedColor == 0xFF000000, onTap: () => notifier.setColor(0xFF000000)),
      _ColorButton(color: 0xFF00FF00, isSelected: state.selectedColor == 0xFF00FF00, onTap: () => notifier.setColor(0xFF00FF00)), // Verde
      _ColorButton(color: 0xFFFFFF00, isSelected: state.selectedColor == 0xFFFFFF00, onTap: () => notifier.setColor(0xFFFFFF00)), // Amarillo
      spacer,
      IconButton(
        icon: const Icon(Icons.delete_sweep, color: AppColors.error),
        onPressed: () => _confirmClear(context, notifier),
        tooltip: 'Borrar todo',
      ),
    ];
  }

  void _confirmClear(BuildContext context, AnnotationNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar notas'),
        content: const Text('¿Deseas eliminar todos los trazos de esta partitura?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () { notifier.clear(); Navigator.pop(context); }, child: const Text('Borrar', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final int color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: isLandscape
            ? const EdgeInsets.symmetric(vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.grey, width: 2) : Border.all(color: Colors.grey.shade300),
        ),
        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      ),
    );
  }
}
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
            ? BoxConstraints(maxHeight: screenHeight * 0.8, maxWidth: 55) 
            : null,
        padding: isLandscape
            ? const EdgeInsets.symmetric(horizontal: 2, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: SingleChildScrollView( // <--- CRÍTICO: Permite que quepa en móviles landscape
          scrollDirection: isLandscape ? Axis.vertical : Axis.horizontal,
          child: isLandscape
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildToolbarItems(context, state, notifier, true),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildToolbarItems(context, state, notifier, false),
                ),
        ),
      ),
    );
  }

  List<Widget> _buildToolbarItems(
    BuildContext context, 
    AnnotationState state, 
    AnnotationNotifier notifier, 
    bool isVertical
  ) {
    final spacer = isVertical 
        ? const SizedBox(height: 8, width: 24, child: Divider(height: 1))
        : const SizedBox(width: 8, height: 24, child: VerticalDivider(width: 1));

    return [
      IconButton(
        icon: Icon(state.isDrawingMode ? Icons.check : Icons.edit_outlined),
        color: state.isDrawingMode ? AppColors.accent : Colors.grey,
        onPressed: notifier.toggleDrawingMode,
        tooltip: 'Modo dibujo',
      ),
      if (state.isDrawingMode) ...[
        _ColorButton(color: 0xFFFF0000, isSelected: state.selectedColor == 0xFFFF0000, onTap: () => notifier.setColor(0xFFFF0000)),
        _ColorButton(color: 0xFF0000FF, isSelected: state.selectedColor == 0xFF0000FF, onTap: () => notifier.setColor(0xFF0000FF)),
        _ColorButton(color: 0xFF000000, isSelected: state.selectedColor == 0xFF000000, onTap: () => notifier.setColor(0xFF000000)),
        spacer,
        IconButton(
          icon: const Icon(Icons.delete_sweep, color: AppColors.error),
          onPressed: () => _confirmClear(context, notifier),
          tooltip: 'Borrar todo',
        ),
      ],
      spacer,
      IconButton(
        icon: Icon(state.isVisible ? Icons.visibility : Icons.visibility_off),
        color: AppColors.accent,
        onPressed: notifier.toggleVisibility,
        tooltip: 'Ver/Ocultar notas',
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
          border: isSelected ? Border.all(color: Colors.white, width: 2) : Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
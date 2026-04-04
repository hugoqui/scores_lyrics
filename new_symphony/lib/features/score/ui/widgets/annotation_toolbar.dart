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

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 4,
      child: Padding(
        padding: isLandscape
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8) // Vertical
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Horizontal
        child: isLandscape
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(state.isDrawingMode ? Icons.edit : Icons.edit_outlined),
              color: state.isDrawingMode ? AppColors.accent : Colors.grey,
              onPressed: notifier.toggleDrawingMode,
              tooltip: 'Modo dibujo',
            ),
            if (state.isDrawingMode) ...[
              _ColorButton(color: 0xFFFF0000, isSelected: state.selectedColor == 0xFFFF0000, onTap: () => notifier.setColor(0xFFFF0000)),
              _ColorButton(color: 0xFF0000FF, isSelected: state.selectedColor == 0xFF0000FF, onTap: () => notifier.setColor(0xFF0000FF)),
              _ColorButton(color: 0xFF000000, isSelected: state.selectedColor == 0xFF000000, onTap: () => notifier.setColor(0xFF000000)),
              const SizedBox(height: 8, width: 24, child: Divider(height: 1)),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: AppColors.error),
                onPressed: () => _confirmClear(context, notifier),
                tooltip: 'Borrar todo',
              ),
            ],
            const SizedBox(height: 8, width: 24, child: Divider(height: 1)),
            IconButton(
              icon: Icon(state.isVisible ? Icons.visibility : Icons.visibility_off),
              color: AppColors.accent,
              onPressed: notifier.toggleVisibility,
              tooltip: 'Ver/Ocultar notas',
            ),
          ],)
            : Row( // Horizontal layout for portrait
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(state.isDrawingMode ? Icons.edit : Icons.edit_outlined), color: state.isDrawingMode ? AppColors.accent : Colors.grey, onPressed: notifier.toggleDrawingMode, tooltip: 'Modo dibujo'),
            if (state.isDrawingMode) ...[
              _ColorButton(color: 0xFFFF0000, isSelected: state.selectedColor == 0xFFFF0000, onTap: () => notifier.setColor(0xFFFF0000)),
              _ColorButton(color: 0xFF0000FF, isSelected: state.selectedColor == 0xFF0000FF, onTap: () => notifier.setColor(0xFF0000FF)),
              _ColorButton(color: 0xFF000000, isSelected: state.selectedColor == 0xFF000000, onTap: () => notifier.setColor(0xFF000000)),
              const SizedBox(width: 8, height: 24, child: VerticalDivider(width: 1)),
              IconButton(icon: const Icon(Icons.delete_sweep, color: AppColors.error), onPressed: () => _confirmClear(context, notifier), tooltip: 'Borrar todo'),
            ],
            const SizedBox(width: 8, height: 24, child: VerticalDivider(width: 1)),
            IconButton(icon: Icon(state.isVisible ? Icons.visibility : Icons.visibility_off), color: AppColors.accent, onPressed: notifier.toggleVisibility, tooltip: 'Ver/Ocultar notas'),
          ],),
      ),
    );
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
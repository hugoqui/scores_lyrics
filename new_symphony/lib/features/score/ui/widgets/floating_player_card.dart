import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:new_symphony/core/constants/app_colors.dart';
import 'package:new_symphony/core/constants/app_dimensions.dart';

class FloatingPlayerCard extends StatelessWidget {
  final bool isArrangementScore; // ¿Estamos viendo la partitura de arreglo?
  final bool isArrangementAudio; // ¿Estamos escuchando el audio de arreglo?
  final bool isLoopEnabled;
  final double playSpeed;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggleAudioMode;
  final VoidCallback onToggleScoreMode; // Nuevo: Para cambiar la partitura
  final VoidCallback onToggleLoop;
  final Function(double) onChangeSpeed;
  final Function(Duration) onSeek; // Nuevo: Para adelantar/atrasar
  final VoidCallback onPlayPause;
  final bool isPlaying;

  const FloatingPlayerCard({
    super.key,
    required this.isArrangementScore,
    required this.isArrangementAudio,
    required this.isLoopEnabled,
    required this.playSpeed,
    required this.position,
    required this.duration,
    required this.onToggleAudioMode,
    required this.onToggleScoreMode,
    required this.onToggleLoop,
    required this.onChangeSpeed,
    required this.onSeek,
    required this.onPlayPause,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Container(
      constraints: isLandscape
          ? BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 65, // Reducido de 80 a 65 para que sea más esbelto
            )
          : const BoxConstraints(maxWidth: 450),
      margin: isLandscape
          ? const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingMedium,
              horizontal: 4, // Reducido para que no flote tan lejos del borde
            )
          : const EdgeInsets.all(AppDimensions.paddingMedium),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: isLandscape
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.7),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: isLandscape
                ? Column(
                    // Vertical layout for landscape
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón Play/Pause siempre visible
                      IconButton(
                        iconSize: 40,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: onPlayPause,
                      ),
                      
                      // Si la altura es mayor a 500px (Tablet), mostramos la barra de progreso
                      if (MediaQuery.of(context).size.height > 500) ...[
                        const SizedBox(height: 8),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3, // Rotar para que sea vertical
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                              ),
                              child: Slider(
                                value: position.inSeconds.toDouble(),
                                max: duration.inSeconds.toDouble() > 0
                                    ? duration.inSeconds.toDouble()
                                    : 1.0,
                                activeColor: AppColors.accent,
                                inactiveColor: Colors.white24,
                                onChanged: (value) =>
                                    onSeek(Duration(seconds: value.toInt())),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else 
                        // En móviles con poca altura, solo agregamos un pequeño espacio flexible
                        const SizedBox(height: 12),

                      // Control de Velocidad
                      _buildActionButton(
                        icon: Icons.speed,
                        label: '${playSpeed}x',
                        onTap: () => _showSpeedMenu(context),
                        isVertical: true,
                      ),
                      
                      // Toggle de Partitura (Melodía / Arreglo)
                      _buildActionButton(
                        icon: isArrangementScore
                            ? Icons.auto_awesome_motion
                            : Icons.description,
                        label: isArrangementScore ? 'Arr.' : 'Mel.',
                        onTap: onToggleScoreMode,
                        isActive: isArrangementScore,
                        isVertical: true,
                      ),
                      
                      // Selector de Audio
                      Opacity(
                        opacity: isArrangementScore ? 1.0 : 0.3,
                        child: _buildActionButton(
                          icon: isArrangementAudio
                              ? Icons.headphones
                              : Icons.person,
                          label: isArrangementAudio ? 'Arr.' : 'Base',
                          onTap: isArrangementScore ? onToggleAudioMode : () {},
                          isActive: isArrangementAudio && isArrangementScore,
                          isVertical: true,
                        ),
                      ),
                      
                      // Botón Loop
                      _buildActionButton(
                        icon: Icons.repeat,
                        label: 'Loop',
                        onTap: onToggleLoop,
                        isActive: isLoopEnabled,
                        isVertical: true,
                      ),
                    ],
                  )
                : Column(
                    // Horizontal layout for portrait
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barra de Progreso (Seek Bar)
                      Row(
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                              ),
                              child: Slider(
                                value: position.inSeconds.toDouble(),
                                max: duration.inSeconds.toDouble() > 0
                                    ? duration.inSeconds.toDouble()
                                    : 1.0,
                                activeColor: AppColors.accent,
                                inactiveColor: Colors.white24,
                                onChanged: (value) =>
                                    onSeek(Duration(seconds: value.toInt())),
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Botones de reproducción en horizontal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Control de Velocidad
                          _buildActionButton(
                            icon: Icons.speed,
                            label: '${playSpeed}x',
                            onTap: () => _showSpeedMenu(context),
                          ),
                          // Toggle de Partitura (Melodía / Arreglo)
                          _buildActionButton(
                            icon: isArrangementScore
                                ? Icons.auto_awesome_motion
                                : Icons.description,
                            label: isArrangementScore
                                ? 'Ver Melodía'
                                : 'Ver Arreglo',
                            onTap: onToggleScoreMode,
                            isActive: isArrangementScore,
                          ),
                          // Botón Play/Pause
                          IconButton(
                            iconSize: 44,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                            ),
                            onPressed: onPlayPause,
                          ),
                          // Selector de Audio (Solo si la partitura es Arreglo)
                          Opacity(
                            opacity: isArrangementScore ? 1.0 : 0.3,
                            child: _buildActionButton(
                              icon: isArrangementAudio
                                  ? Icons.headphones
                                  : Icons.person,
                              label: isArrangementAudio
                                  ? 'Audio: Arr.'
                                  : 'Audio: Base',
                              onTap: isArrangementScore
                                  ? onToggleAudioMode
                                  : () {},
                              isActive:
                                  isArrangementAudio && isArrangementScore,
                            ),
                          ),
                          // Botón Loop
                          _buildActionButton(
                            icon: Icons.repeat,
                            label: 'Loop',
                            onTap: onToggleLoop,
                            isActive: isLoopEnabled,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isVertical = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isVertical ? 8.0 : 0.0,
          horizontal: isVertical ? 0.0 : 4.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.accent : Colors.white,
              size: 24,
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedMenu(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5];
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: speeds
            .map(
              (s) => ListTile(
                title: Text('${s}x'),
                onTap: () {
                  onChangeSpeed(s);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

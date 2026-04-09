import 'package:flutter/material.dart';
import 'package:new_symphony/features/score/providers/annotation_provider.dart';

class OffsetPoint {
  final double x;
  final double y;

  OffsetPoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory OffsetPoint.fromJson(Map<String, dynamic> json) => 
      OffsetPoint((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
  
  Offset toOffset() => Offset(x, y);
}

class DrawingStroke {
  final List<OffsetPoint> points;
  final int color;
  final double weight;
  final AnnotationTool tool;

  DrawingStroke({required this.points, required this.color, this.weight = 3.0, required this.tool});

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color,
    'weight': weight,
  };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) => DrawingStroke(
    points: (json['points'] as List).map((p) => OffsetPoint.fromJson(p)).toList(),
    color: json['color'],
    weight: (json['weight'] as num).toDouble(),
    tool: AnnotationTool.values.firstWhere((tool) => tool.index == json['tool']),
  );
}
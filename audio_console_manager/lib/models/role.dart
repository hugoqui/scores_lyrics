class Role {
  String name;
  int busIndex; // 0 = Main LR, 1-16 = Bus 1-16
  List<int> visibleChannels; // Índices de canales visibles (0-7 para 8 canales)

  Role({
    required this.name,
    required this.busIndex,
    required this.visibleChannels,
  });

  Role copyWith({String? name, int? busIndex, List<int>? visibleChannels}) {
    return Role(
      name: name ?? this.name,
      busIndex: busIndex ?? this.busIndex,
      visibleChannels: visibleChannels ?? List.from(this.visibleChannels),
    );
  }

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      name: json['name'] as String,
      busIndex: json['busIndex'] as int,
      visibleChannels: List<int>.from(json['visibleChannels'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'busIndex': busIndex,
      'visibleChannels': visibleChannels,
    };
  }
}

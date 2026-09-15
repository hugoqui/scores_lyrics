import 'dart:convert';

class MyList {
  final String id;
  final String name;
  final String instrument;
  final List<String> songTitles;

  MyList({
    required this.id,
    required this.name,
    required this.instrument,
    this.songTitles = const [],
  });

  MyList copyWith({String? name, List<String>? songTitles}) {
    return MyList(
      id: id,
      name: name ?? this.name,
      instrument: instrument,
      songTitles: songTitles ?? this.songTitles,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'instrument': instrument,
    'songTitles': songTitles,
  };

  factory MyList.fromJson(Map<String, dynamic> json) => MyList(
    id: json['id'],
    name: json['name'],
    instrument: json['instrument'],
    songTitles: List<String>.from(json['songTitles']),
  );
}
class ApiSong {
  final String title;
  final String chord;

  ApiSong({required this.title, required this.chord});

  factory ApiSong.fromJson(Map<String, dynamic> json) {
    return ApiSong(
      title: json['title'] ?? '',
      chord: json['chord'] ?? 'F',
    );
  }
}
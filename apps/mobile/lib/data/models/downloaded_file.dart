class DownloadedFile {
  final String fileName;
  final String instrument;
  final String chord;

  DownloadedFile({
    required this.fileName,
    required this.instrument,
    required this.chord,
  });

  factory DownloadedFile.fromJson(Map<String, dynamic> json) {
    return DownloadedFile(
      fileName: json['fileName'] ?? '',
      instrument: json['instrument'] ?? '',
      chord: json['chord'] ?? 'F',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'instrument': instrument,
      'chord': chord,
    };
  }
}
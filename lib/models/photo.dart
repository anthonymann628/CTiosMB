class Photo {
  int? id;
  int? routeId;
  int? stopId;
  String filePath;
  DateTime timestamp;

  Photo({
    this.id,
    this.routeId,
    this.stopId,
    required this.filePath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'stopId': stopId,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as int?,
      routeId: map['routeId'] as int?,
      stopId: map['stopId'] as int?,
      filePath: map['filePath'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

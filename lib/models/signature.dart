class Signature {
  int? id;
  int? routeId;
  int? stopId;
  String filePath;
  String? signerName;
  DateTime timestamp;

  Signature({
    this.id,
    this.routeId,
    this.stopId,
    required this.filePath,
    this.signerName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'stopId': stopId,
      'filePath': filePath,
      'signerName': signerName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Signature.fromMap(Map<String, dynamic> map) {
    return Signature(
      id: map['id'] as int?,
      routeId: map['routeId'] as int?,
      stopId: map['stopId'] as int?,
      filePath: map['filePath'] ?? '',
      signerName: map['signerName'],
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

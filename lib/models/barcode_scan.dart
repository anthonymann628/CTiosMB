class BarcodeScan {
  int? id;
  int? routeId;
  int? stopId;
  String code;
  String type;
  DateTime timestamp;

  BarcodeScan({
    this.id,
    this.routeId,
    this.stopId,
    required this.code,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'stopId': stopId,
      'code': code,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BarcodeScan.fromMap(Map<String, dynamic> map) {
    return BarcodeScan(
      id: map['id'] as int?,
      routeId: map['routeId'] as int?,
      stopId: map['stopId'] as int?,
      code: map['code'] ?? '',
      type: map['type'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

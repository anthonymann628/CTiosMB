class RouteModel {
  final String id;
  final String name;
  final String? date;
  final String? type; // ← NEW

  RouteModel({
    required this.id,
    required this.name,
    this.date,
    this.type,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    final jd = map['jobdetailid']?.toString() ?? '';
    final code = map['routeid']?.toString() ?? '';
    final city = map['city']?.toString() ?? '';
    final state = map['state']?.toString() ?? '';
    final rt = map['routetype']?.toString(); // ← NEW

    String nameStr = code.isNotEmpty ? '$code – $city, $state' : '$city, $state';
    String? dateStr;
    if (map['datevalidfrom'] != null) {
      final ts = int.tryParse(map['datevalidfrom'].toString()) ?? 0;
      if (ts > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true).toLocal();
        dateStr = '${dt.month}/${dt.day}/${dt.year}';
      }
    }

    return RouteModel(
      id: jd,
      name: nameStr,
      date: dateStr,
      type: rt, // ← NEW
    );
  }
}

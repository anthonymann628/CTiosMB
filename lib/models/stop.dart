// lib/models/stop.dart

import 'address_detail_product.dart';

class Stop {
  int id;
  int routeId;
  int sequence;
  String name;
  String address;

  bool completed;
  bool uploaded;
  DateTime? completedAt;

  double? latitude;
  double? longitude;

  List<String> barcodes;
  String? photoPath;
  String? signaturePath;

  // ← NEW FIELDS
  bool photoRequired;
  String? side;
  String? custsvc;
  String? notes;
  List<AddressDetailProduct> products;

  Stop({
    required this.id,
    required this.routeId,
    required this.sequence,
    required this.name,
    required this.address,
    this.completed = false,
    this.uploaded = false,
    this.completedAt,
    this.latitude,
    this.longitude,
    this.barcodes = const [],
    this.photoPath,
    this.signaturePath,
    // NEW:
    this.photoRequired = false,
    this.side,
    this.custsvc,
    this.notes,
    this.products = const [],
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      routeId: json['routeId'] is int
          ? json['routeId']
          : int.tryParse(json['routeId']?.toString() ?? '0') ?? 0,
      sequence: json['sequence'] is int
          ? json['sequence']
          : int.tryParse(json['sequence']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      completed: (json['completed'] == 1 || json['completed'] == true),
      uploaded: (json['uploaded'] == 1 || json['uploaded'] == true),
      completedAt: (json['completedAt'] != null)
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      latitude: (json['latitude'] != null)
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: (json['longitude'] != null)
          ? double.tryParse(json['longitude'].toString())
          : null,
      barcodes: <String>[],
      photoPath: json['photoPath']?.toString(),
      signaturePath: json['signaturePath']?.toString(),
      // NEW fields — leave defaults or parse if your JSON includes them:
      photoRequired: (json['photorequired'] == 1 || json['photorequired'] == true),
      side: json['side']?.toString(),
      custsvc: json['custsvc']?.toString(),
      notes: json['notes']?.toString(),
      products: const [], // will be populated via your DatabaseService
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId.toString(),
      'sequence': sequence,
      'name': name,
      'address': address,
      'completed': completed ? 1 : 0,
      'uploaded': uploaded ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      // NEW:
      'photorequired': photoRequired ? 1 : 0,
      'side': side,
      'custsvc': custsvc,
      'notes': notes,
      // barcodes, photoPath, signaturePath, products go in their own tables
    };
  }
}

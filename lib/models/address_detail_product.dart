class AddressDetailProduct {
  final String productCode;
  final int qty;
  final int deliveryId;
  final int jobDetailId;

  AddressDetailProduct({
    required this.productCode,
    required this.qty,
    required this.deliveryId,
    required this.jobDetailId,
  });

  factory AddressDetailProduct.fromMap(Map<String, dynamic> m) {
    return AddressDetailProduct(
      productCode: m['productcode']?.toString() ?? '',
      qty: m['qty'] is int
          ? m['qty']
          : int.tryParse(m['qty']?.toString() ?? '0') ?? 0,
      deliveryId: int.tryParse(m['deliveryid']?.toString() ?? '') ?? 0,
      jobDetailId: int.tryParse(m['jobdetailid']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'productcode': productCode,
        'qty': qty,
        'deliveryid': deliveryId.toString(),
        'jobdetailid': jobDetailId.toString(),
      };
}

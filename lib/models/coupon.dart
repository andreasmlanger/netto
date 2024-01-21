import 'dart:typed_data';

class Coupon {

  final String category;
  final int number;
  final int discount;
  final String type;
  final Uint8List base64Image;

  Coupon({
    required this.category,
    required this.number,
    required this.discount,
    required this.type,
    required this.base64Image
  });
}

/// Model representing a GiangVien (Lecturer).
/// STRICT SCHEMA REQUIREMENT:
/// The collection in MongoDB strictly contains:
/// - IDGV (String)
/// - Fullname (String)
/// - Image (String)
/// - SumClass (Int)
/// plus MongoDB default `_id`.
class GiangVien {
  final String? id; // MongoDB default `_id`
  final String idgv;
  final String fullname;
  final String image;
  final int sumClass;

  GiangVien({
    this.id,
    required this.idgv,
    required this.fullname,
    required this.image,
    required this.sumClass,
  });

  /// Factory constructor to parse JSON document returned from MongoDB Atlas Data API
  factory GiangVien.fromJson(Map<String, dynamic> json) {
    // MongoDB Atlas Data API can return `_id` as either String or Map: {"$oid": "..."}
    String? parsedId;
    if (json['_id'] != null) {
      if (json['_id'] is Map) {
        parsedId = json['_id'][r'$oid']?.toString();
      } else {
        parsedId = json['_id']?.toString();
      }
    }

    // Parse SumClass safely (could be int, num or string)
    int parsedSumClass = 0;
    if (json['SumClass'] != null) {
      if (json['SumClass'] is num) {
        parsedSumClass = (json['SumClass'] as num).toInt();
      } else {
        parsedSumClass = int.tryParse(json['SumClass'].toString()) ?? 0;
      }
    }

    return GiangVien(
      id: parsedId,
      idgv: json['IDGV']?.toString() ?? '',
      fullname: json['Fullname']?.toString() ?? '',
      image: json['Image']?.toString() ?? '',
      sumClass: parsedSumClass,
    );
  }

  /// Converts model to strictly the 4 allowed fields for MongoDB document insertion/updating.
  /// Does NOT include extra metadata fields to satisfy strict exam requirements.
  Map<String, dynamic> toJson() {
    return {
      'IDGV': idgv,
      'Fullname': fullname,
      'Image': image,
      'SumClass': sumClass,
    };
  }

  /// Helper copyWith method for state updates
  GiangVien copyWith({
    String? id,
    String? idgv,
    String? fullname,
    String? image,
    int? sumClass,
  }) {
    return GiangVien(
      id: id ?? this.id,
      idgv: idgv ?? this.idgv,
      fullname: fullname ?? this.fullname,
      image: image ?? this.image,
      sumClass: sumClass ?? this.sumClass,
    );
  }
}

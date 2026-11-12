import 'package:flutter_test/flutter_test.dart';
import 'package:ql_giang_vien/models/giang_vien_model.dart';

void main() {
  group('GiangVien Model Test', () {
    test('Strict schema parsing test', () {
      final json = {
        '_id': {'\$oid': '60c72b2f9b1d8b2bad000001'},
        'IDGV': 'GV01',
        'Fullname': 'Nguyen Van A',
        'Image': 'https://example.com/avatar.png',
        'SumClass': 5,
      };

      final gv = GiangVien.fromJson(json);

      expect(gv.id, '60c72b2f9b1d8b2bad000001');
      expect(gv.idgv, 'GV01');
      expect(gv.fullname, 'Nguyen Van A');
      expect(gv.image, 'https://example.com/avatar.png');
      expect(gv.sumClass, 5);

      final outputJson = gv.toJson();
      expect(outputJson.keys.length, 4);
      expect(outputJson.containsKey('IDGV'), isTrue);
      expect(outputJson.containsKey('Fullname'), isTrue);
      expect(outputJson.containsKey('Image'), isTrue);
      expect(outputJson.containsKey('SumClass'), isTrue);
    });
  });
}

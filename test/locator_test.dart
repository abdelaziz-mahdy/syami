import 'package:flutter_test/flutter_test.dart';
import 'package:syami/controller/locator.dart';

void main() {
  group('mostCommonName', () {
    test('picks the name most results agree on', () {
      expect(
        mostCommonName(['Abu Dhabi', 'Al Reem', 'Abu Dhabi']),
        'Abu Dhabi',
      );
    });

    test('ignores empty and missing names instead of returning a blank', () {
      // What the geocoder returns for central Newcastle upon Tyne.
      expect(mostCommonName(['', '', null, '  ', 'Newcastle']), 'Newcastle');
      expect(mostCommonName(['', '', '', '', '']), isNull);
      expect(mostCommonName(<String?>[]), isNull);
    });

    test('keeps the first name on a tie', () {
      expect(mostCommonName(['Sarajevo', 'Ilidza']), 'Sarajevo');
    });
  });
}

import 'package:php_number_format/php_number_format.dart';
import 'package:test/test.dart';

void main() {
  // Expected strings come from PHP 8.3: php -r 'echo number_format($x, 2);'
  final cases = <num?, String>{
    null: '0.00',
    0: '0.00',
    -0.0: '0.00',
    -0.001: '0.00',
    0.005: '0.01',
    1.005: '1.01',
    17.145: '17.15',
    17.144: '17.14',
    2.675: '2.68',
    1234567.891: '1,234,567.89',
    -1234.5: '-1,234.50',
    999999.995: '1,000,000.00',
    123456789012.345: '123,456,789,012.35',
  };

  cases.forEach((input, expected) {
    test('number_format($input, 2) == $expected', () {
      expect(phpNumberFormat2(input), expected);
    });
  });

  test('non-finite values fall back to 0.00', () {
    expect(phpNumberFormat2(double.nan), '0.00');
    expect(phpNumberFormat2(double.infinity), '0.00');
  });
}

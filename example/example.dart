import 'package:php_number_format/php_number_format.dart';

void main() {
  // The same values the Laravel web page prints with number_format($x, 2).
  print(phpNumberFormat2(17.145)); // 17.15 (a plain Dart round gives 17.14)
  print(phpNumberFormat2(1234567.895)); // 1,234,567.90
  print(phpNumberFormat2(-0.004)); // 0.00
}

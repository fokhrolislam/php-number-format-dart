# php_number_format for Dart

[![tests](https://github.com/fokhrolislam/php-number-format-dart/actions/workflows/test.yml/badge.svg)](https://github.com/fokhrolislam/php-number-format-dart/actions/workflows/test.yml)

PHP's `number_format($value, 2)` reproduced exactly in Dart.

## Why

A Flutter app that shows money next to a Laravel backend will, sooner or later, show a different paisa than the web page for the same value. `17.145` is the classic case:

| | result |
|---|---|
| PHP `number_format(17.145, 2)` | `17.15` |
| Dart `NumberFormat('#,##0.00').format(17.145)` | `17.14` |

The double closest to 17.145 is 17.144999…, so Dart rounds it down. PHP 8.2 and 8.3 first pre-round the value to 15 significant digits (`_php_math_round`), then round half up away from zero, so the web shows `17.15`. Boarding meal rates with four decimals, discounts and GPA averages all hit this.

This package follows the same steps as `ext/standard/math.c` (`_php_math_number_format_ex`, `_php_math_round`, `php_round_helper`, `php_intpow10`, `php_intlog10abs`) in IEEE 754 double arithmetic, so the output matches PHP bit for bit. It was verified against PHP 8.3.32 on more than two million generated values.

## Usage

```dart
import 'package:php_number_format/php_number_format.dart';

phpNumberFormat2(17.145);      // '17.15'
phpNumberFormat2(1234567.891); // '1,234,567.89'
phpNumberFormat2(-0.001);      // '0.00'   (PHP 8 never prints "-0.00")
phpNumberFormat2(null);        // '0.00'
```

Only the two-decimal, default-separator form (`.` decimal, `,` thousands) is implemented, because that is what money needs. Pull requests for other precisions are welcome.

## Known limits

- PHP uses `floor(log10(|x|))`; Dart has no `log10`, so the exponent is found by comparing against powers of ten. Values within one ulp below a power of ten (for example `999.9999999999999`) may differ. Amounts stored with up to four decimals never produce such values.
- For `|x| >= 1e12` PHP skips the pre-round, and for a scaled value `>= 1e15` it skips rounding entirely; both are reproduced.
- Above `1e21` Dart prints exponent notation; unrealistic for money.

## License

MIT

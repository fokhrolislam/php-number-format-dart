import 'dart:math' as math;

/// PHP `number_format($x, 2)` reproduced exactly: ASCII digits, thousands commas,
/// exactly two decimals, PHP 8.2/8.3 rounding. `17.145` → `17.15` (Dart's intl would
/// give `17.14`, because the double is really 17.144999…).
///
/// Mirrors `ext/standard/math.c`: `_php_math_number_format_ex` strips the sign,
/// `_php_math_round(d, dec, PHP_ROUND_HALF_UP)` pre-rounds to 15 significant
/// digits and then rounds half up away from zero, then `"%.2f"`; a value that
/// rounds to 0 loses its sign (PHP 8 never prints "-0.00"). Verified against
/// PHP 8.3.32 on more than two million values.
///
/// Known limits: PHP takes `floor(log10(|x|))`; Dart has no log10, so the
/// exponent is found by comparing against powers of ten, and a value within
/// one ulp below a power of ten may differ. For |x| >= 1e12 PHP skips the
/// pre-round, for a scaled value >= 1e15 it skips rounding; both reproduced.
String phpNumberFormat2(num? raw) {
  var d = (raw ?? 0).toDouble();
  if (!d.isFinite) return '0.00';
  var negative = false;
  if (d < 0) {
    negative = true;
    d = -d;
  }
  d = _phpMathRound(d, 2);
  if (d == 0) {
    // PHP 8: no minus sign once the rounded value is zero; -0.0 is "0.00" too.
    negative = false;
    d = 0.0;
  }
  return '${negative ? '-' : ''}${_group(d.toStringAsFixed(2))}';
}

/// `_php_math_round(value, places, PHP_ROUND_HALF_UP)` from PHP 8.2/8.3.
double _phpMathRound(double value, int places) {
  if (!value.isFinite || value == 0.0) return value;
  final precisionPlaces = 14 - _intLog10Abs(value);
  final f1 = _intPow10(places.abs());
  double tmp;
  if (precisionPlaces > places && precisionPlaces - 15 < places) {
    // Pre-round to 15 significant digits.
    tmp = _roundHalfUp(_roundGetBasic(value, precisionPlaces));
    final usePrecision = places - precisionPlaces; // < 0
    tmp = tmp / _intPow10(usePrecision.abs());
  } else {
    tmp = places >= 0 ? value * f1 : value / f1;
    // PHP: beyond precision, rounding is meaningless.
    if (tmp.abs() >= 1e15) return value;
  }
  tmp = _roundHalfUp(tmp);
  return places > 0 ? tmp / f1 : tmp * f1;
}

/// `php_round_helper(value, PHP_ROUND_HALF_UP)`.
double _roundHalfUp(double v) =>
    v >= 0.0 ? (v + 0.5).floorToDouble() : (v - 0.5).ceilToDouble();

/// `php_round_get_basic(value, places)`.
double _roundGetBasic(double value, int places) {
  final f = _intPow10(places.abs());
  return places >= 0 ? value * f : value / f;
}

/// `php_intpow10(power)`: exact table for 0..22 (each is an exact double), pow otherwise.
double _intPow10(int power) {
  if (power < 0 || power > 22) return math.pow(10.0, power).toDouble();
  return _pow10Table[power];
}

const List<double> _pow10Table = [
  1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, //
  1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22,
];

/// `php_intlog10abs(value)` = floor(log10(|value|)), settled by comparing with powers of ten.
int _intLog10Abs(double value) {
  final a = value.abs();
  var n = (math.log(a) / math.ln10).floor();
  // log/ln10 is off by at most one; settle it exactly.
  while (a < _pow10(n)) {
    n--;
  }
  while (a >= _pow10(n + 1)) {
    n++;
  }
  return n;
}

double _pow10(int n) =>
    n >= 0 && n <= 22 ? _pow10Table[n] : math.pow(10.0, n).toDouble();

/// "1234567.90" → "1,234,567.90" (PHP defaults: '.' decimal point, ',' thousands).
String _group(String fixed) {
  final dot = fixed.indexOf('.');
  final intPart = dot < 0 ? fixed : fixed.substring(0, dot);
  final frac = dot < 0 ? '' : fixed.substring(dot);
  final b = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) b.write(',');
    b.write(intPart[i]);
  }
  return '$b$frac';
}

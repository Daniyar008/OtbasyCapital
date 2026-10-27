String money(int value) {
  final digits = value.abs().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]} ',
  );
  return '${value < 0 ? '-' : ''}$digits ₸';
}

const monthNames = [
  'қаңтар',
  'ақпан',
  'наурыз',
  'сәуір',
  'мамыр',
  'маусым',
  'шілде',
  'тамыз',
  'қыркүйек',
  'қазан',
  'қараша',
  'желтоқсан',
];
String dateLabel(DateTime date) =>
    '${date.day} ${monthNames[date.month - 1]} ${date.year}';
String monthLabel(DateTime date) {
  final month = monthNames[date.month - 1];
  return '${month[0].toUpperCase()}${month.substring(1)} ${date.year}';
}

String percent(num part, num total) =>
    total <= 0 ? '0' : (100 * part / total).toStringAsFixed(0);

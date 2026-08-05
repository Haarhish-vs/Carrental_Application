/// Minimal date formatting used only by the Owner Dashboard, so this
/// rebuild doesn't need to add the `intl` package to `pubspec.yaml`.
abstract final class OwnerDateFormat {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  /// e.g. "12 Aug"
  static String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// e.g. "Wednesday, 12 Aug 2026"
  static String full(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
}

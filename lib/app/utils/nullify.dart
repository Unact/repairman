class Nullify {
  static final List<dynamic> _trueValues = ['true', true, '1', 1];

  static DateTime parseDate(value) {
    return value != null ? (value is DateTime ? value : DateTime.parse(value).toLocal()) : null;
  }

  static double parseDouble(value) {
    return value != null ? (value is double ? value : (value is int ? value.toDouble() : double.parse(value))) : null;
  }

  static bool parseBool(value) {
    return value != null ? (_trueValues.indexOf(value) != -1 ? true : false) : null;
  }
}

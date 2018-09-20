import 'package:intl/intl.dart';

class Format {
  static final _kMondayDateTime = DateTime(2018, 09, 17);

  static String defaultWithTime(DateTime date) {
    return DateFormat.MMMMd('ru').addPattern('HH:mm').format(date);
  }

  static String untilStr(DateTime date) {
    if (date == null) {
      return '';
    } else {
      DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime yesterday = today.subtract(Duration(days: 1));
      DateTime yesterday2 = today.subtract(Duration(days: 2));
      DateTime tomorrow = today.add(Duration(days: 1));
      DateTime tomorrow2 = today.add(Duration(days: 2));
      DateTime tomorrow3 = today.add(Duration(days: 3));
      String strdate;

      if (date.isAfter(yesterday2) && date.isBefore(yesterday)) strdate = 'Позавчера, ';
      if (date.isAfter(yesterday) && date.isBefore(today)) strdate = 'Вчера, ';
      if (date.isAfter(today) && date.isBefore(tomorrow)) strdate = '';
      if (date.isAfter(tomorrow) && date.isBefore(tomorrow2)) strdate = 'Завтра, ';
      if (date.isAfter(tomorrow2) && date.isBefore(tomorrow3)) strdate = 'Послезавтра, ';
      if (strdate == null) strdate = '';

      return strdate + DateFormat.MMMMd('ru').add_jm().format(date);
    }
  }

  static String timeStr(int minutes) {
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime newDate = today.add(Duration(minutes: minutes));

    return DateFormat.Hm().format(newDate);
  }

  static String dayOfWeek(int weekday) {
    String dayName = DateFormat.EEEE('ru').format(_kMondayDateTime.add(Duration(days: weekday - 1)));

    return dayName[0].toUpperCase() + dayName.substring(1);
  }
}

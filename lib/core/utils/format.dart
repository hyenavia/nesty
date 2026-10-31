import 'package:intl/intl.dart';

import '../../features/supplies/data/supply_item.dart';
import '../l10n/app_strings.dart';
import '../../features/routine/widgets/due_pill.dart' show dayUnit;

String fmtKwh(double v, String lang) => NumberFormat('#,##0.0', lang).format(v);
String fmtMoney(num v, String lang) => NumberFormat.decimalPattern(lang).format(v);
String fmtDate(DateTime d, String lang) => DateFormat('d MMM', lang).format(d);

/// "~4 days left" or "Almost out" when 0.
String daysLeftText(AppStrings s, int n) => n <= 0
    ? s.t('almost_out')
    : s.t('days_left', {'n': '$n', 'unit': dayUnit(s, n)});

/// Maps days left to the app-wide Safe / Running low / Out colors.
SupplyStatus statusForDays(int days, {required int lowAt}) => days <= 0
    ? SupplyStatus.out
    : (days <= lowAt ? SupplyStatus.low : SupplyStatus.safe);

String fmtKg(double v, String lang) => fmtKwh(v, lang);

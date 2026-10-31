class MeterReading {
  const MeterReading({required this.at, required this.kwh});
  final DateTime at;
  final double kwh; // what the prepaid meter shows

  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'kwh': kwh};
  factory MeterReading.fromJson(Map<String, dynamic> j) => MeterReading(
        at: DateTime.parse(j['at'] as String),
        kwh: (j['kwh'] as num).toDouble(),
      );
}

class TokenPurchase {
  const TokenPurchase({
    required this.at,
    required this.amountRp,
    this.kwh,
    this.kwhEstimated = false,
  });
  final DateTime at;
  final int amountRp;
  final double? kwh; // from the receipt, or estimated from price per kWh
  final bool kwhEstimated;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'amountRp': amountRp,
        'kwh': kwh,
        'kwhEstimated': kwhEstimated,
      };
  factory TokenPurchase.fromJson(Map<String, dynamic> j) => TokenPurchase(
        at: DateTime.parse(j['at'] as String),
        amountRp: (j['amountRp'] as num).toInt(),
        kwh: (j['kwh'] as num?)?.toDouble(),
        kwhEstimated: j['kwhEstimated'] as bool? ?? false,
      );
}

class TokenState {
  const TokenState(this.readings, this.purchases, this.tariff);
  final List<MeterReading> readings;
  final List<TokenPurchase> purchases;
  final double? tariff; // Rp per kWh, optional
}

enum TokenHint { none, needReading, needKwh, needSecondReading }

class TokenForecast {
  const TokenForecast({
    this.hint = TokenHint.none,
    this.remainingKwh,
    this.ratePerDay,
    this.runOutDate,
  });
  final TokenHint hint;
  final double? remainingKwh;
  final double? ratePerDay;
  final DateTime? runOutDate;

  /// Whole days until the token is predicted to run out (0 = today / overdue).
  int? daysLeft([DateTime? now]) {
    if (runOutDate == null) return null;
    final minutes = runOutDate!.difference(now ?? DateTime.now()).inMinutes;
    final days = (minutes / 1440).round();
    return days < 0 ? 0 : days;
  }
}

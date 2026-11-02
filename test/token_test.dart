import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/features/token/data/token_models.dart';

void main() {
  group('TokenForecast tests', () {
    test('daysLeft calculates remaining days accurately', () {
      final now = DateTime(2026, 11, 1, 12, 0);
      final runOut = DateTime(2026, 11, 4, 12, 0); // 3 days later

      final forecast = TokenForecast(
        remainingKwh: 30.0,
        ratePerDay: 10.0,
        runOutDate: runOut,
      );

      expect(forecast.daysLeft(now), 3);
    });

    test('daysLeft returns 0 when overdue', () {
      final now = DateTime(2026, 11, 5, 12, 0);
      final runOut = DateTime(2026, 11, 4, 12, 0); // 1 day in the past

      final forecast = TokenForecast(
        remainingKwh: 0.0,
        ratePerDay: 10.0,
        runOutDate: runOut,
      );

      expect(forecast.daysLeft(now), 0);
    });

    test('daysLeft returns null when runOutDate is not set', () {
      const forecast = TokenForecast(hint: TokenHint.needReading);
      expect(forecast.daysLeft(), isNull);
    });
  });

  group('MeterReading and TokenPurchase serialization', () {
    test('MeterReading serializes and deserializes correctly', () {
      final dt = DateTime(2026, 10, 31, 10, 0);
      final reading = MeterReading(at: dt, kwh: 45.5);
      final json = reading.toJson();

      expect(json['kwh'], 45.5);
      final fromJson = MeterReading.fromJson(json);
      expect(fromJson.kwh, 45.5);
      expect(fromJson.at, dt);
    });

    test('TokenPurchase serializes and deserializes correctly', () {
      final dt = DateTime(2026, 10, 31, 11, 0);
      final purchase = TokenPurchase(
        at: dt,
        amountRp: 100000,
        kwh: 65.2,
        kwhEstimated: false,
      );
      final json = purchase.toJson();

      expect(json['amountRp'], 100000);
      expect(json['kwh'], 65.2);
      final fromJson = TokenPurchase.fromJson(json);
      expect(fromJson.amountRp, 100000);
      expect(fromJson.kwh, 65.2);
      expect(fromJson.kwhEstimated, false);
    });
  });
}


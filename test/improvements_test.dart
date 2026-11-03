import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/core/modules/module_controller.dart';
import 'package:nesty/features/token/data/token_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModuleController tests', () {
    test('defaults to all modules enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ModuleController(prefs);

      expect(controller.enabledModules, containsAll(ModuleController.allModules));
      expect(controller.isEnabled(ModuleController.moduleToken), isTrue);
      expect(controller.isEnabled(ModuleController.moduleGallon), isTrue);
      expect(controller.isEnabled(ModuleController.moduleLaundry), isTrue);
      expect(controller.isEnabled(ModuleController.moduleSupplies), isTrue);
      expect(controller.isEnabled(ModuleController.moduleBills), isTrue);
    });

    test('can toggle and disable specific modules', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ModuleController(prefs);

      await controller.setEnabled(ModuleController.moduleToken, false);
      expect(controller.isEnabled(ModuleController.moduleToken), isFalse);
      expect(controller.isEnabled(ModuleController.moduleGallon), isTrue);

      // Verify persistence
      final controller2 = ModuleController(prefs);
      expect(controller2.isEnabled(ModuleController.moduleToken), isFalse);
      expect(controller2.isEnabled(ModuleController.moduleGallon), isTrue);
    });

    test('can setAll modules at once (e.g. from onboarding wizard)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ModuleController(prefs);

      await controller.setAll({
        ModuleController.moduleGallon,
        ModuleController.moduleSupplies,
      });

      expect(controller.isEnabled(ModuleController.moduleGallon), isTrue);
      expect(controller.isEnabled(ModuleController.moduleSupplies), isTrue);
      expect(controller.isEnabled(ModuleController.moduleToken), isFalse);
      expect(controller.isEnabled(ModuleController.moduleLaundry), isFalse);
      expect(controller.isEnabled(ModuleController.moduleBills), isFalse);
    });
  });

  group('TokenController Quick Estimation tests', () {
    test('instant forecast using cold-start estimate with only 1 meter reading', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = TokenController(prefs);

      // Add 1 meter reading
      controller.addReading(50.0); // 50 kWh on meter

      // Without estimate, forecast requires second reading
      var forecast = controller.forecast();
      expect(forecast.runOutDate, isNull);
      expect(forecast.daysLeft(), isNull);

      // Set cold start estimate: spend Rp 100,000 lasts 10 days
      // Tariff default = 1,444.70 -> totalKwh = 100,000 / 1444.70 = ~69.217 kWh
      // Daily kWh = ~6.92 kWh/day
      controller.setColdStartEstimate(typicalSpendRp: 100000, typicalDays: 10);

      forecast = controller.forecast();
      expect(forecast.runOutDate, isNotNull);
      expect(forecast.isEstimated, isTrue);
      expect(forecast.daysLeft(), isNotNull);
      expect(forecast.daysLeft()! > 0, isTrue);
    });

    test('clearing cold-start estimate reverts to requiring second reading', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = TokenController(prefs);

      controller.addReading(50.0);
      controller.setColdStartEstimate(typicalSpendRp: 100000, typicalDays: 14);

      expect(controller.forecast().runOutDate, isNotNull);

      controller.clearColdStartEstimate();
      expect(controller.forecast().runOutDate, isNull);
    });
  });
}


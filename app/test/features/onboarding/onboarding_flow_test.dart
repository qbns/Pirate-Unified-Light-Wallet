import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_wallet/features/onboarding/onboarding_flow.dart';

void main() {
  group('OnboardingController.reset', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('preserves selected network and custom endpoint across reset', () {
      final controller = container.read(onboardingControllerProvider.notifier);

      // Simulate developer-mode selection on the create-or-import screen.
      controller
        ..setNetwork(PirateNetwork.regtest)
        ..setCustomEndpoint('127.0.0.1:9067');

      // Tapping "Create"/"Import" resets onboarding before advancing.
      controller.reset(startAt: OnboardingStep.createOrImport);

      final state = container.read(onboardingControllerProvider);
      expect(state.network, PirateNetwork.regtest);
      expect(state.customEndpoint, '127.0.0.1:9067');
      // Other fields are still cleared by reset.
      expect(state.mode, isNull);
      expect(state.mnemonic, isNull);
      expect(state.currentStep, OnboardingStep.createOrImport);
    });

    test('defaults to mainnet with no endpoint when nothing selected', () {
      final controller = container.read(onboardingControllerProvider.notifier);

      controller.reset();

      final state = container.read(onboardingControllerProvider);
      expect(state.network, PirateNetwork.mainnet);
      expect(state.customEndpoint, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/core/capsules/public_config_capsule.dart';

void main() {
  group('PublicConfigState', () {
    test('aiGenerationEnabled defaults to false when unloaded', () {
      expect(const PublicConfigState().aiGenerationEnabled, isFalse);
      expect(const PublicConfigState().passwordResetEnabled, isFalse);
      expect(const PublicConfigState().hasLoaded, isFalse);
    });

    test('aiGenerationEnabled reflects loaded public config', () {
      const enabled = PublicConfigState(
        config: PublicConfig(
          passwordResetEnabled: true,
          requireEmailVerification: false,
          aiGenerationEnabled: true,
        ),
        hasLoaded: true,
      );
      expect(enabled.aiGenerationEnabled, isTrue);
      expect(enabled.passwordResetEnabled, isTrue);

      const disabled = PublicConfigState(
        config: PublicConfig(
          passwordResetEnabled: false,
          requireEmailVerification: false,
          aiGenerationEnabled: false,
        ),
        hasLoaded: true,
      );
      expect(disabled.aiGenerationEnabled, isFalse);
    });

    test('copyWith preserves config when only flags change', () {
      const original = PublicConfigState(
        config: PublicConfig(
          passwordResetEnabled: false,
          requireEmailVerification: false,
          aiGenerationEnabled: true,
        ),
        hasLoaded: true,
      );
      final next = original.copyWith(isLoading: true, error: null);
      expect(next.config?.aiGenerationEnabled, isTrue);
      expect(next.isLoading, isTrue);
      expect(next.hasLoaded, isTrue);
    });
  });
}

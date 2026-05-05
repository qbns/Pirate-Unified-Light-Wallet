import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pirate_wallet/core/security/clipboard_manager.dart';

void main() {
  group('ClipboardManager lifecycle policy', () {
    test('does not clear on resumed state', () {
      expect(
        ClipboardManager.shouldClearOnLifecycleState(AppLifecycleState.resumed),
        isFalse,
      );
    });

    test('can keep transient inactive state in the foreground', () {
      expect(
        ClipboardManager.shouldClearOnLifecycleState(
          AppLifecycleState.inactive,
          inactiveIsBackground: false,
        ),
        isFalse,
      );
    });

    test(
      'preserves timed clipboard when inactive is treated as background',
      () {
        expect(
          ClipboardManager.shouldClearOnLifecycleState(
            AppLifecycleState.inactive,
          ),
          isFalse,
        );
      },
    );

    test('preserves timed clipboard on real background states', () {
      const states = <AppLifecycleState>[
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
      ];

      for (final state in states) {
        expect(
          ClipboardManager.shouldClearOnLifecycleState(
            state,
            inactiveIsBackground: false,
          ),
          isFalse,
        );
      }

      expect(
        ClipboardManager.shouldClearOnLifecycleState(
          AppLifecycleState.detached,
          inactiveIsBackground: false,
        ),
        isTrue,
      );
    });

    test(
      'can opt into immediate background clearing for stricter contexts',
      () {
        expect(
          ClipboardManager.shouldClearOnLifecycleState(
            AppLifecycleState.paused,
            inactiveIsBackground: false,
            preserveTimedClipboardOnBackground: false,
          ),
          isTrue,
        );
      },
    );

    test('preserves timed clipboard during desktop focus changes', () {
      const preservedStates = <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ];

      for (final state in preservedStates) {
        expect(
          ClipboardManager.shouldClearOnLifecycleState(
            state,
            inactiveIsBackground: false,
          ),
          isFalse,
        );
      }

      expect(
        ClipboardManager.shouldClearOnLifecycleState(
          AppLifecycleState.detached,
          inactiveIsBackground: false,
        ),
        isTrue,
      );
    });
  });

  group('ClipboardManager clipboard contents', () {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    String? clipboardText;

    setUp(() {
      ClipboardManager.cancelAutoClear();
      clipboardText = null;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'Clipboard.setData':
              final arguments = methodCall.arguments as Map<dynamic, dynamic>;
              clipboardText = arguments['text'] as String?;
              return null;
            case 'Clipboard.getData':
              return <String, dynamic>{'text': clipboardText};
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      ClipboardManager.cancelAutoClear();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    test('lifecycle keeps seed available until timer expires', () async {
      const seed = 'alpha bravo charlie delta';
      await ClipboardManager.copySeed(
        seed,
        clearAfter: const Duration(seconds: 30),
      );

      await ClipboardManager.handleAppLifecycleState(
        AppLifecycleState.hidden,
        inactiveIsBackground: false,
      );

      expect(clipboardText, seed);

      await ClipboardManager.handleAppLifecycleState(
        AppLifecycleState.paused,
        inactiveIsBackground: false,
      );

      expect(clipboardText, seed);
    });

    test(
      'explicit strict policy can still clear managed seed immediately',
      () async {
        const seed = 'alpha bravo charlie delta';
        await ClipboardManager.copySeed(
          seed,
          clearAfter: const Duration(seconds: 30),
        );

        await ClipboardManager.handleAppLifecycleState(
          AppLifecycleState.paused,
          inactiveIsBackground: false,
          preserveTimedClipboardOnBackground: false,
        );

        expect(clipboardText, '');
      },
    );
  });
}

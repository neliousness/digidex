import 'package:digidexplus/ads/ad_service.dart';
import 'package:digidexplus/config/ad_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InterstitialPacer', () {
    late DateTime now;
    InterstitialPacer pacer({int every = 5, Duration gap = const Duration(seconds: 90)}) => InterstitialPacer(every: every, minGap: gap, now: () => now);

    setUp(() => now = DateTime(2026, 11, 2, 12));

    test('is due on the 5th details screen, then counts again after it is shown', () {
      final p = pacer();
      expect([for (var i = 0; i < 4; i++) p.recordOpen()], everyElement(isFalse));
      expect(p.recordOpen(), isTrue);
      p.shown();
      now = now.add(const Duration(minutes: 5));
      expect([for (var i = 0; i < 4; i++) p.recordOpen()], everyElement(isFalse));
      expect(p.recordOpen(), isTrue);
    });

    test('never within the minimum gap of the last one, however many screens', () {
      final p = pacer();
      for (var i = 0; i < 5; i++) {
        p.recordOpen();
      }
      p.shown();
      now = now.add(const Duration(seconds: 30));
      final quick = [for (var i = 0; i < 12; i++) p.recordOpen()];
      expect(quick, everyElement(isFalse), reason: '12 screens in 30s: still too soon');

      now = now.add(const Duration(seconds: 61));
      expect(p.recordOpen(), isTrue, reason: '91s later and well past 5 screens');
    });

    test('an ad that was due but not shown (no fill) stays due', () {
      final p = pacer();
      for (var i = 0; i < 4; i++) {
        p.recordOpen();
      }
      expect(p.recordOpen(), isTrue);
      // Nothing to show: shown() is not called.
      expect(p.recordOpen(), isTrue);
    });

    test('defaults come from AdConfig', () {
      final p = InterstitialPacer(now: () => now);
      expect(p.every, AdConfig.detailOpensPerInterstitial);
      expect(p.minGap, AdConfig.minTimeBetweenInterstitials);
    });
  });

  test('ads are off in tests (not Android or iOS)', () async {
    expect(AdConfig.supported, isFalse);
    expect(await const NoAdService().ready, isFalse);
  });
}

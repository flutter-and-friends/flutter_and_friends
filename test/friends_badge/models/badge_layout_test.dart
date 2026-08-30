import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BadgeLayout', () {
    test('panel size matches friends_badge 3.7" BWRY spec (240x416)', () {
      expect(kBadgePanelSize, const Size(240, 416));
    });

    group('imageOnly', () {
      final layout = BadgeLayout.forTemplate(BadgeTemplate.imageOnly);

      test('image covers the full panel', () {
        expect(layout.imageRect, Offset.zero & kBadgePanelSize);
      });

      test('has no text rects', () {
        expect(layout.nameRect, Rect.zero);
        expect(layout.roleRect, Rect.zero);
        expect(layout.nameMaxFontSize, 0);
        expect(layout.roleMaxFontSize, 0);
      });

      test('draws no chrome', () {
        expect(layout.dividerY, isNull);
        expect(layout.borderWidth, 0);
        expect(layout.accentStripeRect, isNull);
      });
    });

    group('classic', () {
      final layout = BadgeLayout.forTemplate(BadgeTemplate.classic);

      test('image occupies roughly the top 60%', () {
        expect(layout.imageRect.top, 0);
        expect(layout.imageRect.left, 0);
        expect(layout.imageRect.width, kBadgePanelSize.width);
        expect(
          layout.imageRect.height,
          closeTo(kBadgePanelSize.height * 0.6, 0.001),
        );
      });

      test('divider sits at the image/text boundary', () {
        final dividerY = layout.dividerY!;
        expect(dividerY, greaterThan(layout.imageRect.bottom - 2));
        expect(dividerY, lessThan(layout.nameRect.top));
      });

      test('name above role, both below divider', () {
        expect(layout.nameRect.top, greaterThan(layout.dividerY!));
        expect(layout.roleRect.top, greaterThan(layout.nameRect.top));
        expect(
          layout.roleRect.bottom,
          lessThanOrEqualTo(kBadgePanelSize.height),
        );
      });

      test('name is larger than role', () {
        expect(layout.nameMaxFontSize, greaterThan(layout.roleMaxFontSize));
      });

      test('text renders dark on light', () {
        expect(layout.textOnDark, isFalse);
      });
    });

    group('overlay', () {
      final layout = BadgeLayout.forTemplate(BadgeTemplate.overlay);

      test('image covers the full panel (band draws on top)', () {
        expect(layout.imageRect, Offset.zero & kBadgePanelSize);
      });

      test('text rects sit in a bottom band', () {
        final bandTop = layout.nameRect.top;
        expect(bandTop, greaterThan(kBadgePanelSize.height / 2));
        expect(
          layout.roleRect.bottom,
          lessThanOrEqualTo(kBadgePanelSize.height),
        );
      });

      test('text renders light on dark', () {
        expect(layout.textOnDark, isTrue);
      });

      test('name above role', () {
        expect(layout.nameRect.top, lessThan(layout.roleRect.top));
      });
    });

    group('framed', () {
      final layout = BadgeLayout.forTemplate(BadgeTemplate.framed);

      test('image is inset from the panel edges', () {
        expect(layout.imageRect.left, greaterThan(0));
        expect(layout.imageRect.top, greaterThan(0));
        expect(layout.imageRect.right, lessThan(kBadgePanelSize.width));
        expect(layout.imageRect.bottom, lessThan(kBadgePanelSize.height));
      });

      test('has a thick border', () {
        expect(layout.borderWidth, greaterThanOrEqualTo(4));
      });

      test('accent stripe sits between image and text', () {
        final stripe = layout.accentStripeRect!;
        expect(stripe.top, greaterThanOrEqualTo(layout.imageRect.bottom));
        expect(stripe.bottom, lessThanOrEqualTo(layout.nameRect.top));
        expect(stripe.width, layout.imageRect.width);
      });

      test('text below stripe, name above role', () {
        expect(
          layout.nameRect.top,
          greaterThan(layout.accentStripeRect!.bottom),
        );
        expect(layout.roleRect.top, greaterThan(layout.nameRect.top));
      });
    });
  });

  group('breakBadgeText', () {
    test('leaves short text alone', () {
      expect(breakBadgeText('Lukas'), 'Lukas');
      expect(breakBadgeText('Flutter!'), 'Flutter!');
    });

    test('breaks at the first space at or after 8 characters', () {
      expect(breakBadgeText('Software Engineer'), 'Software\nEngineer');
      expect(
        breakBadgeText('Johannes Pietilä Löhnn'),
        'Johannes\nPietilä Löhnn',
      );
      expect(
        breakBadgeText('Senior Flutter Developer'),
        'Senior Flutter\nDeveloper',
      );
    });

    test('does not break when the only spaces come before 8 characters', () {
      expect(breakBadgeText('Lukas Klingsbo'), 'Lukas Klingsbo');
      expect(breakBadgeText('SDK Engineer'), 'SDK Engineer');
    });

    test('never breaks text without spaces', () {
      expect(breakBadgeText('Supercalifragilistic'), 'Supercalifragilistic');
    });

    test('inserts at most one break', () {
      expect(
        breakBadgeText('Senior Flutter Developer at Acme'),
        'Senior Flutter\nDeveloper at Acme',
      );
    });

    test('ignores a trailing space', () {
      expect(breakBadgeText('Software '), 'Software ');
    });
  });

  group('fitFontSize', () {
    // Stub measurer: 10 px per character per font-size-10 unit, i.e.
    // width = text.length * fontSize. Deterministic, no TextPainter.
    double stubMeasure(String text, double fontSize) => text.length * fontSize;

    test('returns maxFontSize when text already fits', () {
      expect(
        fitFontSize(
          text: 'abc', // 3 * 20 = 60 <= 100
          maxWidth: 100,
          maxFontSize: 20,
          minFontSize: 10,
          measure: stubMeasure,
        ),
        20,
      );
    });

    test('shrinks to the largest fitting size', () {
      // 'abcdef' at size 10 is 60px wide; at 20 it's 120. Max width 100
      // -> best fit is size 16 (6*16=96) or 17 (6*17=102 too wide).
      final fitted = fitFontSize(
        text: 'abcdef',
        maxWidth: 100,
        maxFontSize: 20,
        minFontSize: 10,
        measure: stubMeasure,
      );
      expect(fitted, greaterThanOrEqualTo(16));
      expect(fitted, lessThanOrEqualTo(17));
    });

    test('clamps to minFontSize when nothing fits', () {
      expect(
        fitFontSize(
          text: 'a_very_long_string_that_will_never_fit',
          maxWidth: 10,
          maxFontSize: 20,
          minFontSize: 10,
          measure: stubMeasure,
        ),
        10,
      );
    });

    test('empty text returns maxFontSize', () {
      expect(
        fitFontSize(
          text: '',
          maxWidth: 1,
          maxFontSize: 20,
          minFontSize: 10,
          measure: stubMeasure,
        ),
        20,
      );
    });
  });

  group('truncateToFit', () {
    double stubMeasure(String text, double fontSize) => text.length * fontSize;

    test('returns text unchanged when it fits', () {
      expect(
        truncateToFit(
          text: 'abc',
          maxWidth: 100,
          fontSize: 10,
          measure: stubMeasure,
        ),
        'abc',
      );
    });

    test('truncates with an ellipsis to the longest fitting prefix', () {
      // 'abcdef' at size 10 is 60px; maxWidth 40 fits 4 chars total,
      // one of which is the ellipsis -> 'abc…'.
      expect(
        truncateToFit(
          text: 'abcdef',
          maxWidth: 40,
          fontSize: 10,
          measure: stubMeasure,
        ),
        'abc…',
      );
    });

    test('returns just the ellipsis when even one character overflows', () {
      expect(
        truncateToFit(
          text: 'abcdef',
          maxWidth: 10,
          fontSize: 10,
          measure: stubMeasure,
        ),
        '…',
      );
    });

    test('empty text returns empty', () {
      expect(
        truncateToFit(
          text: '',
          maxWidth: 0,
          fontSize: 10,
          measure: stubMeasure,
        ),
        '',
      );
    });
  });

  group('coverSourceRect', () {
    test('portrait source into portrait dest crops horizontally', () {
      // 400x800 source into 100x200 dest: same aspect ratio, no crop.
      final rect = coverSourceRect(
        source: const Size(400, 800),
        dest: const Rect.fromLTWH(0, 0, 100, 200),
      );
      expect(rect, const Rect.fromLTWH(0, 0, 400, 800));
    });

    test('wide source into portrait dest crops the sides', () {
      // 800x400 source into 100x200 dest: dest aspect 0.5, source 2.0 ->
      // scale to height, crop width.
      final rect = coverSourceRect(
        source: const Size(800, 400),
        dest: const Rect.fromLTWH(0, 0, 100, 200),
      );
      // Scale = max(100/800, 200/400) = 0.5. Crop window: 200x400.
      expect(rect.width, 200);
      expect(rect.height, 400);
      // Centered horizontally.
      expect(rect.left, (800 - 200) / 2);
      expect(rect.top, 0);
    });

    test('tall source into wide dest crops top and bottom', () {
      // 400x800 source into 200x100 dest: dest aspect 2.0, source 0.5.
      final rect = coverSourceRect(
        source: const Size(400, 800),
        dest: const Rect.fromLTWH(0, 0, 200, 100),
      );
      // Scale = max(200/400, 100/800) = 0.5. Crop window: 400x200.
      expect(rect.width, 400);
      expect(rect.height, 200);
      expect(rect.left, 0);
      expect(rect.top, (800 - 200) / 2);
    });

    test('square source into portrait dest crops sides', () {
      // 1000x1000 into 240x416 (the badge panel).
      final rect = coverSourceRect(
        source: const Size(1000, 1000),
        dest: Offset.zero & const Size(240, 416),
      );
      // Scale = max(240/1000, 416/1000) = 0.416. Crop: 240/0.416 x 1000.
      expect(rect.height, 1000);
      expect(rect.width, closeTo(240 / 0.416, 0.001));
    });

    test('result always stays inside the source bounds', () {
      final rect = coverSourceRect(
        source: const Size(1200, 630),
        dest: const Rect.fromLTWH(10, 10, 240, 416),
      );
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(1200));
      expect(rect.bottom, lessThanOrEqualTo(630));
    });
  });
}

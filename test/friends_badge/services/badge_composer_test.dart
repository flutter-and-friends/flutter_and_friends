import 'dart:typed_data';

import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final panelWidth = kBadgePanelSize.width.toInt();
  final panelHeight = kBadgePanelSize.height.toInt();

  group('badgeImageFromRgba', () {
    test('builds an 8-bit RGBA image of the panel size', () {
      final rgba = Uint8List(panelWidth * panelHeight * 4);
      for (var i = 0; i < rgba.length; i += 4) {
        rgba[i] = 255;
        rgba[i + 1] = 0;
        rgba[i + 2] = 0;
        rgba[i + 3] = 255;
      }

      final badge = badgeImageFromRgba(rgba);
      final image = badge.getDitheredImage(img.DitherKernel.none);

      expect(image.width, panelWidth);
      expect(image.height, panelHeight);
      expect(image.format, img.Format.uint8);
      final pixel = image.getPixel(panelWidth ~/ 2, panelHeight ~/ 2);
      expect((pixel.r, pixel.g, pixel.b), (255, 0, 0));
    });

    test('rejects byte lengths that do not match the panel', () {
      expect(
        () => badgeImageFromRgba(Uint8List(16)),
        throwsArgumentError,
      );
    });
  });

  group('BadgeComposer.renderRgba', () {
    Future<BadgeImage> compose(
      img.Image source,
      BadgeTemplate template,
    ) async {
      final uiImage = await BadgeComposer.toUiImage(source);
      addTearDown(uiImage.dispose);
      final rgba = await BadgeComposer.renderRgba(
        sourceImage: uiImage,
        template: template,
        name: 'Name',
        role: 'Role',
        font: BadgeFont.display,
      );
      return badgeImageFromRgba(rgba);
    }

    test('produces exactly one 8-bit RGBA buffer of the panel size', () async {
      final source = img.Image(width: 32, height: 32)
        ..clear(img.ColorRgb8(255, 0, 0));
      final uiImage = await BadgeComposer.toUiImage(source);
      addTearDown(uiImage.dispose);

      final rgba = await BadgeComposer.renderRgba(
        sourceImage: uiImage,
        template: BadgeTemplate.imageOnly,
        name: '',
        role: '',
        font: BadgeFont.display,
      );

      expect(rgba.lengthInBytes, panelWidth * panelHeight * 4);
    });

    test('a solid red source dithers to a solid red panel', () async {
      final source = img.Image(width: 32, height: 32)
        ..clear(img.ColorRgb8(255, 0, 0));

      final badge = await compose(source, BadgeTemplate.imageOnly);
      final dithered = badge.getDitheredImage(img.DitherKernel.atkinson);

      var red = 0;
      for (final pixel in dithered) {
        if (pixel.r == 255 && pixel.g == 0 && pixel.b == 0) red++;
      }
      expect(red, panelWidth * panelHeight);
    });

    test('the classic divider survives as a black line', () async {
      final source = img.Image(width: 32, height: 32)
        ..clear(img.ColorRgb8(255, 255, 255));
      final layout = BadgeLayout.forTemplate(BadgeTemplate.classic);

      final badge = await compose(source, BadgeTemplate.classic);
      final dithered = badge.getDitheredImage(img.DitherKernel.atkinson);

      final y = layout.dividerY!.floor();
      for (var x = 0; x < panelWidth; x++) {
        final pixel = dithered.getPixel(x, y);
        expect((pixel.r, pixel.g, pixel.b), (0, 0, 0), reason: 'x=$x');
      }
    });
  });
}

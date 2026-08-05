// Regenerates the web icons from the native app icons, so web matches
// Android and iOS instead of shipping the `flutter create` placeholders.
//
//   regular icons + favicon  <- the iOS 1024pt master (full-bleed)
//   maskable icons           <- the Android adaptive foreground, composited
//                               onto the adaptive background colour
//
// Run: dart run tool/gen_web_icons.dart
import 'dart:io';

import 'package:image/image.dart';

const _iosMaster = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/1024.png';
const _androidFg =
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png';

/// Matches `android/app/src/main/res/values/ic_launcher_background.xml`.
final _background = ColorRgb8(0xD6, 0xEF, 0xFC);

Image _resize(Image src, int size) => copyResize(
  src,
  width: size,
  height: size,
  interpolation: Interpolation.average,
);

void main() {
  final ios = decodePng(File(_iosMaster).readAsBytesSync())!;
  final foreground = decodePng(File(_androidFg).readAsBytesSync())!;

  // Android's adaptive safe zone is tighter than the web maskable spec's
  // centre-80% circle, so the artwork needs no repositioning here.
  final maskable = Image(width: foreground.width, height: foreground.height)
    ..clear(_background);
  compositeImage(maskable, foreground);

  for (final size in [192, 512]) {
    File(
      'web/icons/Icon-$size.png',
    ).writeAsBytesSync(encodePng(_resize(ios, size)));
    File(
      'web/icons/Icon-maskable-$size.png',
    ).writeAsBytesSync(encodePng(_resize(maskable, size)));
  }
  File('web/favicon.png').writeAsBytesSync(encodePng(_resize(ios, 32)));

  stdout.writeln('Wrote web/favicon.png and web/icons/Icon*.png');
}

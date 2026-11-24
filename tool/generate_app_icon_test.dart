import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _cream = ui.Color(0xFFFFF7E9);
const _teal = ui.Color(0xFF237F75);
const _lightTeal = ui.Color(0xFF49AA96);
const _orange = ui.Color(0xFFFFB85C);

void main() {
  test('generate PETCARE launcher icons', () async {
    final outputs = <String, int>{
      'assets/icon/petcare_icon.png': 1024,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png':
          1024,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png':
          120,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png':
          120,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png':
          180,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png':
          152,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png':
          167,
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    };

    for (final entry in outputs.entries) {
      final bytes = await _renderIcon(entry.value);
      final output = File(entry.key);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes);
    }
  });
}

Future<List<int>> _renderIcon(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final scale = size / 1024;
  canvas.scale(scale);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 1024, 1024),
    ui.Paint()..color = _cream,
  );

  final tile = ui.RRect.fromRectAndRadius(
    const ui.Rect.fromLTWH(32, 32, 960, 960),
    const ui.Radius.circular(220),
  );
  canvas.drawRRect(
    tile,
    ui.Paint()
      ..color = _teal.withValues(alpha: 0.24)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 28),
  );
  canvas.drawRRect(
    tile.shift(const ui.Offset(0, -8)),
    ui.Paint()
      ..shader = ui.Gradient.linear(ui.Offset(150, 100), ui.Offset(880, 920), [
        _lightTeal,
        _teal,
      ]),
  );

  final glowPaint = ui.Paint()..color = _cream.withValues(alpha: 0.08);
  canvas.drawCircle(const ui.Offset(834, 232), 240, glowPaint);
  canvas.drawCircle(
    const ui.Offset(222, 825),
    185,
    ui.Paint()..color = const ui.Color(0xFF9AD8B9).withValues(alpha: 0.12),
  );

  final toePaint = ui.Paint()..color = _cream;
  canvas.drawOval(
    ui.Rect.fromCenter(
      center: const ui.Offset(326, 403),
      width: 156,
      height: 190,
    ),
    toePaint,
  );
  canvas.drawOval(
    ui.Rect.fromCenter(
      center: const ui.Offset(476, 325),
      width: 154,
      height: 188,
    ),
    toePaint,
  );
  canvas.drawOval(
    ui.Rect.fromCenter(
      center: const ui.Offset(636, 325),
      width: 154,
      height: 188,
    ),
    toePaint,
  );
  canvas.drawOval(
    ui.Rect.fromCenter(
      center: const ui.Offset(788, 403),
      width: 156,
      height: 190,
    ),
    toePaint,
  );

  final heart = ui.Path()
    ..moveTo(557, 754)
    ..cubicTo(519, 724, 363, 626, 363, 531)
    ..cubicTo(363, 443, 477, 412, 557, 508)
    ..cubicTo(637, 412, 751, 443, 751, 531)
    ..cubicTo(751, 626, 595, 724, 557, 754)
    ..close();
  canvas.drawPath(heart, ui.Paint()..color = _orange);

  final sparkle = ui.Paint()
    ..color = _cream.withValues(alpha: 0.94)
    ..strokeWidth = 18
    ..strokeCap = ui.StrokeCap.round;
  canvas.drawLine(
    const ui.Offset(228, 635),
    const ui.Offset(228, 693),
    sparkle,
  );
  canvas.drawLine(
    const ui.Offset(199, 664),
    const ui.Offset(257, 664),
    sparkle,
  );
  canvas.drawCircle(
    const ui.Offset(790, 707),
    12,
    ui.Paint()..color = _cream.withValues(alpha: 0.9),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The Closero wordmark: full lettering with the ring built into the
/// final "o". Geometry is ported 1:1 from the locked
/// CloseroWordMarkProto.svg (the path strings below are verbatim);
/// recolored only, never redrawn. Never pair with a separate icon.
///
/// Placement is locked to onboarding: 400px hero on the welcome step,
/// 60px in the topbar after.
class CloseroWordmark extends StatelessWidget {
  const CloseroWordmark({super.key, required this.width, this.color});

  /// Locked sizes: 400 (onboarding hero), 60 (onboarding topbar).
  final double width;

  /// Defaults to hi1.
  final Color? color;

  /// viewBox 3745 x 1112.
  static const double aspectRatio = 3745 / 1112;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Closero',
      child: CustomPaint(
        size: Size(width, width / aspectRatio),
        painter: _WordmarkPainter(color ?? context.closColors.hi1),
      ),
    );
  }
}

/// Letter outlines from the locked SVG, drawn in font coordinates
/// (y-up, flipped by the group's scale(1,-1)). Each glyph carries its
/// translate(x,0) offset.
const List<(double, String)> _glyphs = [
  (
    0,
    'M333 -14Q205 -14 130.0 58.5Q55 131 55 268V432Q55 569 130.0 641.5'
        'Q205 714 333 714Q459 714 527.5 644.0Q596 574 596 453V448H489V456'
        'Q489 527 450.5 572.0Q412 617 333 617Q253 617 208.0 568.5'
        'Q163 520 163 434V266Q163 180 208.0 131.5Q253 83 333 83'
        'Q412 83 450.5 128.0Q489 173 489 244V261H596V247Q596 126 527.5 56.0'
        'Q459 -14 333 -14Z'
  ),
  (643, 'M76 0V700H179V0Z'),
  (
    899,
    'M307 -14Q233 -14 175.5 16.5Q118 47 85.0 104.0Q52 161 52 239V254'
        'Q52 332 85.0 388.5Q118 445 175.5 476.0Q233 507 307 507'
        'Q381 507 439.0 476.0Q497 445 530.0 388.5Q563 332 563 254V239'
        'Q563 161 530.0 104.0Q497 47 439.0 16.5Q381 -14 307 -14Z'
        'M307 78Q375 78 417.5 121.5Q460 165 460 242V251Q460 328 417.5 371.5'
        'Q375 415 307 415Q239 415 197.0 371.5Q155 328 155 251V242'
        'Q155 165 197.5 121.5Q240 78 307 78Z'
  ),
  (
    1514,
    'M278 -14Q183 -14 121.0 28.0Q59 70 46 155L142 178Q153 116 190.5 92.5'
        'Q228 69 278 69Q327 69 353.5 87.5Q380 106 380 137Q380 167 355.0 181.0'
        'Q330 195 282 204L247 210Q197 219 156.0 236.0Q115 253 91.0 283.0'
        'Q67 313 67 360Q67 430 119.0 468.5Q171 507 257 507Q340 507 393.5 469.5'
        'Q447 432 463 368L367 341Q358 386 329.0 404.5Q300 423 257 423'
        'Q215 423 191.0 407.5Q167 392 167 364Q167 334 190.5 320.0'
        'Q214 306 254 299L289 293Q342 284 385.5 267.5Q429 251 455.0 221.5'
        'Q481 192 481 142Q481 67 425.5 26.5Q370 -14 278 -14Z'
  ),
  (
    2039,
    'M302 -14Q227 -14 171.0 17.5Q115 49 83.5 106.0Q52 163 52 240V252'
        'Q52 329 83.5 386.0Q115 443 170.0 475.0Q225 507 298 507'
        'Q369 507 422.5 475.5Q476 444 506.0 388.0Q536 332 536 257V218H157'
        'Q159 153 200.5 114.5Q242 76 304 76Q362 76 391.5 102.0'
        'Q421 128 437 162L523 118Q508 90 482.0 59.0Q456 28 412.0 7.0'
        'Q368 -14 302 -14ZM158 297H432Q427 352 391.0 384.0Q355 416 297 416'
        'Q239 416 202.5 384.0Q166 352 158 297Z'
  ),
  (
    2623,
    'M76 0V493H177V435H193Q205 466 231.0 480.5Q257 495 297 495H356V402H293'
        'Q242 402 210.5 374.5Q179 347 179 290V0Z'
  ),
];

// Final "o" ring, from the locked SVG's ellipse + mask.
const Offset _ringCenter = Offset(3317.50, -246.50);
const double _ringRx = 201.94;
const double _ringRy = 206.94;
const double _ringStroke = 107.12;
// Mask rect (x, y, w, h), rotated -60 degrees about the ring center.
const Rect _ringGap = Rect.fromLTWH(2978.85, -267.92, 677.30, 42.85);

class _WordmarkPainter extends CustomPainter {
  const _WordmarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Map the viewBox "-60 -760 3745 1112" onto the canvas.
    final u = size.width / 3745;
    canvas.scale(u);
    canvas.translate(60, 760);

    final fill = Paint()..color = color;

    // Letters live inside a scale(1,-1) group (font coordinates).
    canvas.save();
    canvas.scale(1, -1);
    for (final (dx, d) in _glyphs) {
      canvas.save();
      canvas.translate(dx, 0);
      canvas.drawPath(_parsePathData(d), fill);
      canvas.restore();
    }
    canvas.restore();

    // The ring with its -60 degree gap, like the SVG mask: draw the
    // stroke on a layer, then clear the rotated strip.
    final ringBounds = Rect.fromCenter(
      center: _ringCenter,
      width: 2 * (_ringRx + _ringStroke),
      height: 2 * (_ringRy + _ringStroke),
    );
    canvas.saveLayer(ringBounds, Paint());
    canvas.drawOval(
      Rect.fromCenter(
        center: _ringCenter,
        width: 2 * _ringRx,
        height: 2 * _ringRy,
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringStroke,
    );
    canvas.translate(_ringCenter.dx, _ringCenter.dy);
    canvas.rotate(-60 * math.pi / 180);
    canvas.drawRect(
      _ringGap.shift(-_ringCenter),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WordmarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Parses the locked SVG path data (absolute M/L/H/V/Q/Z only, which is
/// all the wordmark uses) so the geometry strings stay verbatim.
Path _parsePathData(String d) {
  final path = Path();
  var x = 0.0;
  var y = 0.0;
  var i = 0;

  bool numberChar(int index) {
    final c = d.codeUnitAt(index);
    return (c >= 0x30 && c <= 0x39) || c == 0x2E /* . */;
  }

  double number() {
    while (i < d.length && (d[i] == ' ' || d[i] == ',')) {
      i++;
    }
    final start = i;
    if (i < d.length && d[i] == '-') i++;
    while (i < d.length && numberChar(i)) {
      i++;
    }
    return double.parse(d.substring(start, i));
  }

  while (i < d.length) {
    final command = d[i++];
    switch (command) {
      case ' ':
        break;
      case 'M':
        x = number();
        y = number();
        path.moveTo(x, y);
      case 'L':
        x = number();
        y = number();
        path.lineTo(x, y);
      case 'H':
        x = number();
        path.lineTo(x, y);
      case 'V':
        y = number();
        path.lineTo(x, y);
      case 'Q':
        final cx = number();
        final cy = number();
        x = number();
        y = number();
        path.quadraticBezierTo(cx, cy, x, y);
      case 'Z':
        path.close();
      default:
        throw FormatException('Unsupported path command: $command');
    }
  }
  return path;
}

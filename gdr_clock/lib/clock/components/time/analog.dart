import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:gdr_clock/clock/clock.dart';

const handBounceDuration = Duration(milliseconds: 274);

class AnimatedAnalogComponent extends AnimatedWidget {
  final Animation<double> animation;
  final ClockModel model;

  AnimatedAnalogComponent({
    Key key,
    @required this.animation,
    @required this.model,
  })  : assert(animation != null),
        assert(model != null),
        super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    final bounce = const HandBounceCurve().transform(animation.value),
        time = DateTime.now();

    return AnalogComponent(
      textStyle: Theme.of(context).textTheme.display1,
      secondHandAngle: -pi / 2 +
          // Regular distance
          pi * 2 / 60 * time.second +
          // Bounce
          pi * 2 / 60 * (bounce - 1),
      minuteHandAngle: -pi / 2 +
          pi * 2 / 60 * time.minute +
          // Bounce only when the minute changes.
          (time.second != 0 ? 0 : pi * 2 / 60 * (bounce - 1)),
      hourHandAngle:
          // Angle equal to 0 starts on the right side and not on the top.
          -pi / 2 +
              // Distance for the hour.
              pi *
                  2 /
                  (model.is24HourFormat ? 24 : 12) *
                  (model.is24HourFormat ? time.hour : time.hour % 12) +
              // Distance for the minute.
              pi * 2 / (model.is24HourFormat ? 24 : 12) / 60 * time.minute +
              // Distance for the second.
              pi * 2 / (model.is24HourFormat ? 24 : 12) / 60 / 60 * time.second,
      hourDivisions: model.is24HourFormat ? 24 : 12,
    );
  }
}

/// Curve describing the bouncing motion of the clock hands.
///
/// [ElasticOutCurve] already showed the overshoot beyond the destination position well,
/// however, the oscillation movement back to before the destination position was not pronounced enough.
/// Changing [ElasticOutCurve.period] to values greater than `0.4` will decrease how much the
/// curve oscillates as a whole, but I only wanted to decrease the magnitude of the first part
/// of the oscillation and increase the second to match real hand movement more closely,
/// hence, I created [HandBounceCurve].
///
/// I used this [slow motion capture of a watch](https://youtu.be/tyl7-gHRBX8?t=29) as a guide.
class HandBounceCurve extends Curve {
  const HandBounceCurve();

  @override
  double transformInternal(double t) {
    final b = .4;
    // todo implement transformations
    return 1 + pow(2, -10 * t) * sin(((t - b / 4) * pi * 2) / b);
  }
}

class AnalogComponent extends LeafRenderObjectWidget {
  final double secondHandAngle, minuteHandAngle, hourHandAngle;
  final TextStyle textStyle;
  final int hourDivisions;

  const AnalogComponent({
    Key key,
    @required this.textStyle,
    @required this.secondHandAngle,
    @required this.minuteHandAngle,
    @required this.hourHandAngle,
    @required this.hourDivisions,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderAnalogPart(
      textStyle: textStyle,
      secondHandAngle: secondHandAngle,
      minuteHandAngle: minuteHandAngle,
      hourHandAngle: hourHandAngle,
      hourDivisions: hourDivisions,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderAnalogPart renderObject) {
    renderObject.update(
      textStyle: textStyle,
      secondHandAngle: secondHandAngle,
      minuteHandAngle: minuteHandAngle,
      hourHandAngle: hourHandAngle,
      hourDivisions: hourDivisions,
    );
  }
}

class RenderAnalogPart extends RenderClockComponent {
  double secondHandAngle, minuteHandAngle, hourHandAngle;
  TextStyle textStyle;
  int hourDivisions;

  RenderAnalogPart({
    this.textStyle,
    this.secondHandAngle,
    this.minuteHandAngle,
    this.hourHandAngle,
    this.hourDivisions,
  }) : super(ClockComponent.analogTime);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // (for formatting reasons)
  }

  @override
  void detach() {
    // (for formatting reasons)
    super.detach();
  }

  void update({
    double radius,
    TextStyle textStyle,
    double secondHandAngle,
    double minuteHandAngle,
    double hourHandAngle,
    int hourDivisions,
  }) {
    this.textStyle = textStyle;
    this.secondHandAngle = secondHandAngle;
    this.minuteHandAngle = minuteHandAngle;
    this.hourHandAngle = hourHandAngle;
    this.hourDivisions = hourDivisions;

    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  double _radius;

  @override
  void performResize() {
    size = constraints.biggest;

    _radius = size.height / 2;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    canvas.save();
    // Translate the canvas to the center of the square.
    canvas.translate(offset.dx + size.width / 2, offset.dy + size.height / 2);

    canvas.drawOval(Rect.fromCircle(center: Offset.zero, radius: _radius),
        Paint()..color = const Color(0xffffd345));

    final largeDivisions = hourDivisions, smallDivisions = 60;

    // Ticks indicating minutes and seconds (both 60).
    for (var n = smallDivisions; n > 0; n--) {
      // Do not draw small ticks when large ones will be drawn afterwards anyway.
      if (n % (smallDivisions / largeDivisions) != 0) {
        final height = 8.3;
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(0, (-size.width + height) / 2),
                width: 1.3,
                height: height),
            Paint()
              ..color = const Color(0xff000000)
              ..blendMode = BlendMode.darken);
      }

      canvas.rotate(-pi * 2 / smallDivisions);
    }

    // Ticks and numbers indicating hours.
    for (var n = largeDivisions; n > 0; n--) {
      final height = 4.2;
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(0, (-size.width + height) / 2),
              width: 3.1,
              height: height),
          Paint()
            ..color = const Color(0xff000000)
            ..blendMode = BlendMode.darken);

      final painter = TextPainter(
          text: TextSpan(text: '$n', style: textStyle),
          textDirection: TextDirection.ltr);
      painter.layout();
      painter.paint(
          canvas,
          Offset(
              -painter.width / 2,
              -size.height / 2 +
                  // Push the numbers inwards a bit.
                  9.6));

      canvas.rotate(-pi * 2 / largeDivisions);
    }

    // Hand displaying the current hour.
    canvas.drawLine(
        Offset.zero,
        Offset.fromDirection(hourHandAngle, size.width / 3.1),
        Paint()
          ..color = const Color(0xff000000)
          ..strokeWidth = 13.7
          ..strokeCap = StrokeCap.butt);

    // Hand displaying the current minute.
    canvas.drawLine(
        Offset.zero,
        Offset.fromDirection(minuteHandAngle, size.width / 2.3),
        Paint()
          ..color = const Color(0xff000000)
          ..strokeWidth = 8.4
          ..strokeCap = StrokeCap.square);

    // Hand displaying the current second.
    canvas.drawLine(
        Offset.zero,
        Offset.fromDirection(secondHandAngle, size.width / 2.1),
        Paint()
          ..color = const Color(0xff000000)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);

    canvas.restore();
  }
}
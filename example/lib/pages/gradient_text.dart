import 'dart:math';

import 'package:example/text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum DrawGradientShape {
  none,
  heart,
  star,
}

@FFRoute(
    name: 'fluttercandies://GradientText',
    routeName: 'GradientText',
    description: 'quickly build gradient text')
class GradientText extends StatefulWidget {
  const GradientText({super.key});

  @override
  State<GradientText> createState() => _GradientTextState();
}

class _GradientTextState extends State<GradientText> {
  GradientConfig _config = GradientConfig(
    gradient: const LinearGradient(
      colors: <Color>[Colors.blue, Colors.red],
    ),
    ignoreRegex: GradientConfig.ignoreEmojiRegex,
    ignoreWidgetSpan: true,
    renderMode: GradientRenderMode.fullText,
  );
  DrawGradientShape _drawGradientShape = DrawGradientShape.none;
  final MySpecialTextSpanBuilder _builder = MySpecialTextSpanBuilder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('quickly build gradient text'),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: 20),
              const Text('Ignore WidgetSpan:'),
              Checkbox(
                value: _config.ignoreWidgetSpan,
                onChanged: (bool? value) {
                  setState(() {
                    _config = _config.copyWith(ignoreWidgetSpan: value!);
                  });
                },
              ),
              const Spacer(),
              const Text('Ignore Emoji:'),
              Checkbox(
                value: _config.ignoreRegex != null,
                onChanged: (bool? value) {
                  setState(
                    () {
                      _config = _config.copyWithIgnoreRegex(
                          value! ? GradientConfig.ignoreEmojiRegex : null);
                    },
                  );
                },
              ),
            ],
          ),
          Row(
            children: <Widget>[
              const SizedBox(width: 20),
              PopupMenuButton<GradientRenderMode>(
                itemBuilder: (BuildContext context) {
                  return GradientRenderMode.values.map((GradientRenderMode e) {
                    return PopupMenuItem<GradientRenderMode>(
                      value: e,
                      child: Text(e.name),
                    );
                  }).toList();
                },
                onSelected: (GradientRenderMode value) {
                  setState(() {
                    _config = _config.copyWith(renderMode: value);
                  });
                },
                initialValue: _config.renderMode,
                child: Text('GradientMode: ${_config.renderMode.name}'),
              ),
              const Spacer(),
              PopupMenuButton<DrawGradientShape>(
                itemBuilder: (BuildContext context) {
                  return DrawGradientShape.values.map((DrawGradientShape e) {
                    return PopupMenuItem<DrawGradientShape>(
                      value: e,
                      child: Text(e.name),
                    );
                  }).toList();
                },
                onSelected: (DrawGradientShape shape) {
                  setState(() {
                    _drawGradientShape = shape;
                    _config = _config.copyWith(
                      beforeDrawGradient: _beforeDrawGradient,
                    );
                  });
                },
                initialValue: _drawGradientShape,
                child: Text('DrawGradientShape: ${_drawGradientShape.name}'),
              ),
              const SizedBox(width: 20),
            ],
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('System Api:'),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: <Color>[Colors.blue, Colors.red],
                        ).createShader(bounds);
                      },
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: Container(
                                width: 20,
                                height: 20,
                                color: Colors.red,
                              ),
                            ),
                            const TextSpan(
                              text: '🤭我会被作用于渐变效果🤭',
                              style: TextStyle(color: Colors.green),
                            ),
                            WidgetSpan(
                              child: Container(
                                width: 20,
                                height: 20,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          WidgetSpan(
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Colors.red,
                            ),
                          ),
                          const TextSpan(
                            text: '🤭我会被作用于渐变效果🤭',
                            style: TextStyle(color: Colors.green),
                          ),
                          WidgetSpan(
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: <Color>[Colors.blue, Colors.red],
                          ).createShader(
                            const Rect.fromLTWH(0, 0, 200, 50),
                          ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('ExtendedText Api:'),
                    const SizedBox(height: 20),
                    ExtendedText.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          IgnoreGradientTextSpan(
                            text: '我不会被作用于',
                            children: const <InlineSpan>[
                              TextSpan(
                                  text: '渐变效果',
                                  style: TextStyle(color: Colors.green)),
                            ],
                          ),
                          _builder.build(
                            '''[love]🤭\$Flutter Candies\$ (糖果群) 成立于 2019 年 2 月 14 日，聚集了一群热爱 Flutter 的开发者们，糖果群致力于通过持续创建、维护和贡献高质量的 Flutter 插件和库 (Flutter / Dart Packages)，让 Flutter 更易用，助力开发者们更快、更高效地构建优秀的 Flutter 应用。\$Flutter Candies\$ 已经在 pub.dev 上开源了 71 个 实用的 packages，不仅如此，我们还构建了很多实用工具、API、实战项目以及优质的技术文章，帮助 Flutter 开发者们在职业生涯的不同阶段快速成长。我们希望号召和帮助更多开发者们为 Flutter 开发者更多实用的插件库 (小糖果)，如果你有同样的目标和理想，糖果群欢迎你的加入！@zmtzawqlp [sun_glasses]''',
                            onTap: (dynamic parameter) {
                              if (parameter.toString().startsWith('\$')) {
                                launchUrl(Uri.parse(
                                    'https://github.com/fluttercandies'));
                              } else if (parameter.toString().startsWith('@')) {
                                launchUrl(
                                    Uri.parse('mailto:zmtzawqlp@live.com'));
                              }
                            },
                          ),
                          IgnoreGradientTextSpan(
                            text: '我也不会被作用于',
                            children: const <InlineSpan>[
                              TextSpan(
                                  text: '渐变效果',
                                  style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 20),
                      gradientConfig: _config,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _beforeDrawGradient(
    PaintingContext context,
    TextPainter textPainter,
    Offset offset,
  ) {
    final Rect rect = offset & textPainter.size;
    Path? path;

    switch (_drawGradientShape) {
      case DrawGradientShape.heart:
        path = clipheart(rect);
        break;
      case DrawGradientShape.star:
        path = clipStar(rect);
        break;
      case DrawGradientShape.none:
    }
    if (path != null) {
      context.canvas.drawPath(
        path,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      context.canvas.clipPath(path);
    }
  }

  Path clipheart(Rect rect) {
    const int numPoints = 1000;
    final List<Offset> points = <Offset>[];
    const double dt = 2 * pi / numPoints;

    for (double t = 0.0; t <= 2 * pi; t += dt) {
      final Offset oo = Offset(doX(t), doY(t));
      points.add(oo);
    }

    double wxmin = points[0].dx;
    double wxmax = wxmin;
    double wymin = points[0].dy;
    double wymax = wymin;

    for (final Offset point in points) {
      if (wxmin > point.dx) {
        wxmin = point.dx;
      }
      if (wxmax < point.dx) {
        wxmax = point.dx;
      }
      if (wymin > point.dy) {
        wymin = point.dy;
      }
      if (wymax < point.dy) {
        wymax = point.dy;
      }
    }

    final Rect boundingRect =
        Rect.fromLTWH(wxmin, wymin, wxmax - wxmin, wymax - wymin);

    final double scale = min(rect.width / boundingRect.width,
            rect.height / boundingRect.height) *
        0.9;

    final Offset rectCenter = rect.center;

    final List<Offset> scaledPoints = points.map((Offset point) {
      final double x =
          rectCenter.dx + (point.dx - boundingRect.center.dx) * scale;
      final double y =
          rectCenter.dy + (point.dy - boundingRect.center.dy) * scale * -1;
      return Offset(x, y);
    }).toList();

    return Path()..addPolygon(scaledPoints, true);
  }

  double doX(double t) {
    final double sinT = sin(t);
    return 16 * sinT * sinT * sinT;
  }

  double doY(double t) {
    return 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t);
  }

  Path clipStar(Rect rect) {
    const int numPoints = 5;
    final List<Offset> points = <Offset>[];
    final double outerRadius = min(rect.width, rect.height) / 2;
    final double innerRadius = outerRadius / 2.5;
    final Offset center = rect.center;
    const double angleStep = pi / numPoints;

    for (int i = 0; i < numPoints * 2; i++) {
      final bool isEven = i % 2 == 0;
      final double radius = isEven ? outerRadius : innerRadius;
      final double angle = i * angleStep - pi / 2;
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);
      points.add(Offset(x, y));
    }

    return Path()..addPolygon(points, true);
  }
}

class IgnoreGradientTextSpan extends TextSpan with IgnoreGradientSpan {
  IgnoreGradientTextSpan({String? text, List<InlineSpan>? children})
      : super(
          text: text,
          children: children,
        );
}

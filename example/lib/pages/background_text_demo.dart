import 'package:extended_text/extended_text.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

@FFRoute(
    name: 'fluttercandies://BackgroundTextDemo',
    routeName: 'BackgroundText',
    description: 'workaround for issue 24335/24337 about background')
class BackgroundTextDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nick background for text'),
      ),
      body: SingleChildScrollView(
        child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(TextSpan(children: <TextSpan>[
                  TextSpan(
                      text: '24335',
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri.parse(
                              'https://github.com/flutter/flutter/issues/24335'));
                        }),
                  const TextSpan(text: '/'),
                  TextSpan(
                      text: '24337',
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri.parse(
                              'https://github.com/flutter/flutter/issues/24337'));
                        }),
                ])),
                const Text(
                  'official text background with color Alpha 255, chinese words are missing',
                ),
                Text(
                  '错误演示 12345',
                  style: TextStyle(background: Paint()..color = Colors.orange),
                ),
                Container(
                  height: 20.0,
                ),
                const Text(
                  'official text background with color Alpha 102, it has a hightlight line at top',
                ),
                Text(
                  '错误演示 12345',
                  style: TextStyle(
                      background: Paint()
                        ..color = Colors.orange.withOpacity(0.4)),
                ),
                Container(
                  height: 20.0,
                ),
                const Text(
                    'Following demo is workaround for issue 24335/24337 about background,for more you can define your custom background too.'),
                Container(
                  height: 20.0,
                ),
                ExtendedText.rich(
                  TextSpan(children: <TextSpan>[
                    BackgroundTextSpan(
                      text: '错误演示 12345',
                      background: Paint()..color = Colors.blue,
                    ),
                    BackgroundTextSpan(
                        text: '错误演示 12345',
                        background: Paint()..color = Colors.blue,
                        style: const TextStyle(color: Colors.white)),
                    const TextSpan(
                        text: ' extended text with nice background '),
                    BackgroundTextSpan(
                      text:
                          '错误演示 12345  错误演示 12345  错误演示 12345  错误演示 12345  错误演示 12345  错误演示 12345',
                      background: Paint()..color = Colors.orange,
                    ),
                    const TextSpan(
                        text:
                            '  extended text with nice background,only problem is that we can get offset of ellipsis,so can\'t paint background at end of ellipsis. please let me know if any way to get offset of ellipsis.'),
                    BackgroundTextSpan(
                      text: 'paint background end of line 错误演示12345',
                      style: const TextStyle(color: Colors.red),
                      background: Paint()..color = Colors.red.withOpacity(0.1),
                    ),
                  ]),
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  height: 20.0,
                ),
                ExtendedText.rich(TextSpan(children: <TextSpan>[
                  BackgroundTextSpan(
                      text:
                          'This text has nice background with borderradius,no mattter how many line,it likes nice',
                      background: Paint()..color = Colors.indigo,
                      clipBorderRadius:
                          const BorderRadius.all(Radius.circular(3.0))),
                ])),
                Container(
                  height: 20.0,
                ),
                ExtendedText.rich(TextSpan(children: <TextSpan>[
                  BackgroundTextSpan(
                      text:
                          'if you don\'t like default background, you can use paintBackground call back to draw your background',
                      background: Paint()..color = Colors.teal,
                      clipBorderRadius:
                          const BorderRadius.all(Radius.circular(3.0)),
                      paintBackground: (BackgroundTextSpan backgroundTextSpan,
                          Canvas canvas,
                          Offset offset,
                          TextPainter? painter,
                          Rect rect,
                          {Offset? endOffset,
                          TextPainter? wholeTextPainter}) {
                        final Rect textRect = offset & painter!.size;

                        ///top-right
                        if (endOffset != null) {
                          final Rect firstLineRect = offset &
                              Size(rect.right - offset.dx, painter.height);

                          if (backgroundTextSpan.clipBorderRadius != null) {
                            canvas.save();
                            canvas.clipPath(Path()
                              ..addRRect(backgroundTextSpan.clipBorderRadius!
                                  .resolve(painter.textDirection)
                                  .toRRect(firstLineRect)));
                          }

                          ///start
                          canvas.drawRect(
                              firstLineRect, backgroundTextSpan.background);

                          if (backgroundTextSpan.clipBorderRadius != null) {
                            canvas.restore();
                          }

                          ///endOffset.y has deviation,so we calculate with text height
                          final int fullLinesAndLastLine =
                              ((endOffset.dy - offset.dy) / painter.height)
                                  .round();

                          double y = offset.dy;
                          for (int i = 0; i < fullLinesAndLastLine; i++) {
                            y += painter.height;
                            //last line
                            if (i == fullLinesAndLastLine - 1) {
                              final Rect lastLineRect = Offset(0.0, y) &
                                  Size(endOffset.dx, painter.height);
                              if (backgroundTextSpan.clipBorderRadius != null) {
                                canvas.save();
                                canvas.clipPath(Path()
                                  ..addRRect(backgroundTextSpan
                                      .clipBorderRadius!
                                      .resolve(painter.textDirection)
                                      .toRRect(lastLineRect)));
                              }
                              canvas.drawRect(
                                  lastLineRect, backgroundTextSpan.background);
                              if (backgroundTextSpan.clipBorderRadius != null) {
                                canvas.restore();
                              }
                            }

                            ///draw full line
                            else {
                              final Rect fullLineRect = Offset(0.0, y) &
                                  Size(rect.width, painter.height);

                              if (backgroundTextSpan.clipBorderRadius != null) {
                                canvas.save();
                                canvas.clipPath(Path()
                                  ..addRRect(backgroundTextSpan
                                      .clipBorderRadius!
                                      .resolve(painter.textDirection)
                                      .toRRect(fullLineRect)));
                              }

                              ///draw full line
                              canvas.drawRect(
                                  fullLineRect, backgroundTextSpan.background);

                              if (backgroundTextSpan.clipBorderRadius != null) {
                                canvas.restore();
                              }
                            }
                          }
                        } else {
                          if (backgroundTextSpan.clipBorderRadius != null) {
                            canvas.save();
                            canvas.clipPath(Path()
                              ..addRRect(backgroundTextSpan.clipBorderRadius!
                                  .resolve(painter.textDirection)
                                  .toRRect(textRect)));
                          }

                          canvas.drawRect(
                              textRect, backgroundTextSpan.background);

                          if (backgroundTextSpan.clipBorderRadius != null) {
                            canvas.restore();
                          }
                        }

                        ///remember return true to igore default background
                        return true;
                      }),
                ])),
              ],
            )),
      ),
    );
  }
}

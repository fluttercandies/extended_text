// GENERATED CODE - DO NOT MODIFY MANUALLY
// **************************************************************************
// Auto generated by https://github.com/fluttercandies/ff_annotation_route
// **************************************************************************
// ignore_for_file: prefer_const_literals_to_create_immutables,unused_local_variable,unused_import,unnecessary_import
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/widgets.dart';

import 'pages/background_text_demo.dart';
import 'pages/custom_text_overflow_demo.dart';
import 'pages/join_zero_width_space.dart';
import 'pages/main_page.dart';
import 'pages/regexp_text_demo.dart';
import 'pages/text_demo.dart';
import 'pages/text_selection_demo.dart';

FFRouteSettings getRouteSettings({
  required String name,
  Map<String, dynamic>? arguments,
  PageBuilder? notFoundPageBuilder,
}) {
  final Map<String, dynamic> safeArguments =
      arguments ?? const <String, dynamic>{};
  switch (name) {
    case 'fluttercandies://BackgroundTextDemo':
      return FFRouteSettings(
        name: name,
        arguments: arguments,
        builder: () => BackgroundTextDemo(),
        routeName: 'BackgroundText',
        description: 'workaround for issue 24335/24337 about background',
      );
    case 'fluttercandies://CustomTextOverflowDemo':
      return FFRouteSettings(
        name: name,
        arguments: arguments,
        builder: () => CustomTextOverflowDemo(),
        routeName: 'CustomTextOverflow',
        description: 'workaround for issue 26748. how to custom text overflow',
      );
    case 'fluttercandies://JoinZeroWidthSpace':
      return FFRouteSettings(
        name: name,
        arguments: arguments,
        builder: () => JoinZeroWidthSpaceDemo(),
        routeName: 'JoinZeroWidthSpace',
        description:
            'make line breaking and overflow style better, workaround for issue 18761.',
      );
    case 'fluttercandies://RegExpTextDemo':
      return FFRouteSettings(
        name: name,
        arguments: arguments,
        builder: () => RegExpTextDemo(),
        routeName: 'RegExText',
        description: 'quickly build special text with RegExp',
      );
    case 'fluttercandies://TextDemo':
      return FFRouteSettings(
        name: name,
        arguments: arguments,
        builder: () => TextDemo(),
        routeName: 'Text',
        description: 'quickly build special text',
      );
    case 'fluttercandies://TextSelectionDemo':
      return FFRouteSettings(
        name: name,
        arguments: arguments,
        builder: () => TextSelectionDemo(),
        routeName: 'TextSelection',
        description: 'text selection support',
      );
    case 'fluttercandies://mainpage':
      return FFRouteSettings(
        name: name,
        arguments: arguments,
        builder: () => MainPage(),
        routeName: 'MainPage',
      );
    default:
      return FFRouteSettings(
        name: FFRoute.notFoundName,
        routeName: FFRoute.notFoundRouteName,
        builder: notFoundPageBuilder ?? () => Container(),
      );
  }
}

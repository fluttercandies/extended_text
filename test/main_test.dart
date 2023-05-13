// import 'package:extended_text/extended_text.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// void main() {
//   testWidgets(
//       'widget should display go to bottom button when the bottom of the page is not visible',
//       (WidgetTester tester) async {
//     final Widget w = _buildWidget();
//     await tester.pumpWidget(w);
//   });
// }

// Widget _buildWidget() {
//   return MaterialApp(
//       home: Scaffold(
//           body: ConstrainedBox(
//     constraints: const BoxConstraints(maxHeight: 100, maxWidth: 100),
//     child: Container(
//         width: 50,
//         height: 50,
//         child: ExtendedText.rich(
//           _buildText(),
//           maxLines: 5,
//           overflow: TextOverflow.clip,
//           overflowWidget: TextOverflowWidget(
//             align: TextOverflowAlign.left,
//             child: Container(
//               child: const Text('overflow'),
//               height: 100,
//               width: 100,
//             ),
//           ),
//         )),
//   )));
// }

// TextSpan _buildText() {
//   return const TextSpan(text: 'text');
// }

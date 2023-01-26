import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../example_route.dart';
import '../example_routes.dart' as example_routes;

@FFRoute(
  name: 'fluttercandies://mainpage',
  routeName: 'MainPage',
)
class MainPage extends StatelessWidget {
  MainPage() {
    final List<String> routeNames = <String>[];
    routeNames.addAll(example_routes.routeNames);
    routeNames.remove('fluttercandies://picswiper');
    routeNames.remove('fluttercandies://mainpage');
    routes.addAll(routeNames
        .map<FFRouteSettings>((String name) => getRouteSettings(name: name)));
  }
  final List<FFRouteSettings> routes = <FFRouteSettings>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('ExtendedText'),
        actions: <Widget>[
          ButtonTheme(
            minWidth: 0.0,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextButton(
              child: const Text(
                'Github',
                style: TextStyle(
                  decorationStyle: TextDecorationStyle.solid,
                  decoration: TextDecoration.underline,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                launchUrl(Uri.parse(
                    'https://github.com/fluttercandies/extended_text'));
              },
            ),
          ),
          if (!kIsWeb)
            ButtonTheme(
              padding: const EdgeInsets.only(right: 10.0),
              minWidth: 0.0,
              child: TextButton(
                child: Image.network(
                    'https://pub.idqqimg.com/wpa/images/group.png'),
                onPressed: () {
                  launchUrl(Uri.parse('https://jq.qq.com/?_wv=1027&k=5bcc0gy'));
                },
              ),
            )
        ],
      ),
      body: ListView.builder(
        itemBuilder: (BuildContext c, int index) {
          final FFRouteSettings page = routes[index];
          return Container(
              margin: const EdgeInsets.all(20.0),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      (index + 1).toString() + '.' + page.routeName!,
                      //style: TextStyle(inherit: false),
                    ),
                    Text(
                      page.description!,
                      style: const TextStyle(color: Colors.grey),
                    )
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(context, routes[index].name!);
                },
              ));
        },
        itemCount: routes.length,
      ),
    );
  }
}

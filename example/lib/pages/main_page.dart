
import 'package:flutter/material.dart';
import 'package:ff_annotation_route/ff_annotation_route.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:example/example_routes.dart';

import '../example_route.dart';

@FFRoute(
  name: "fluttercandies://mainpage",
  routeName: "MainPage",
)
class MainPage extends StatelessWidget {
  final List<RouteResult> routes = List<RouteResult>();
  MainPage() {
    final List<String> temp= routeNames.toList();
    temp.remove("fluttercandies://mainpage");
    routes.addAll(
        temp.map<RouteResult>((name) => getRouteResult(name: name)));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("ExtendedText"),
         actions: <Widget>[
          ButtonTheme(
            minWidth: 0.0,
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: FlatButton(
              child: Text(
                'Github',
                style: TextStyle(
                  decorationStyle: TextDecorationStyle.solid,
                  decoration: TextDecoration.underline,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                launch('https://github.com/fluttercandies/extended_text');
              },
            ),
          ),
          ButtonTheme(
            padding: EdgeInsets.only(right: 10.0),
            minWidth: 0.0,
            child: FlatButton(
              child:
                  Image.network('https://pub.idqqimg.com/wpa/images/group.png'),
              onPressed: () {
                launch('https://jq.qq.com/?_wv=1027&k=5bcc0gy');
              },
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemBuilder: (c, index) {
          var page = routes[index];
          return Container(
              margin: EdgeInsets.all(20.0),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      (index + 1).toString() + "." + page.routeName,
                      //style: TextStyle(inherit: false),
                    ),
                    Text(
                      page.description,
                      style: TextStyle(color: Colors.grey),
                    )
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(context, routes[index].name);
                },
              ));
        },
        itemCount: routes.length,
      ),
    );
  }
}

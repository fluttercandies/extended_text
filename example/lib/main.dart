import 'package:example/background_text_demo.dart';
import 'package:example/common/tu_chong_repository.dart';
import 'package:example/custom_text_overflow_demo.dart';
import 'package:example/custom_image_demo.dart';
import 'package:example/text_demo.dart';
import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Page> pages = new List<Page>();
  TuChongRepository listSourceRepository;
  @override
  void initState() {
    clearExtendedTextDiskCachedImages();
    // TODO: implement initState
    pages.add(Page(PageType.Text, "quickly build special text"));
    pages.add(Page(PageType.CustomImage, "custom inline-image in text"));
    pages.add(Page(PageType.BackgroundText,
        "workaround for issue 24335/24337 about background"));
    pages.add(Page(PageType.CustomTextOverflow,
        "workaround for issue 26748. how to custom text overflow"));

    listSourceRepository = new TuChongRepository();
    listSourceRepository.loadData().then((result) {
      if (listSourceRepository.length > 0) {
        // _imageTestUrl = listSourceRepository.first.imageUrl;
        _imageTestUrls =
            listSourceRepository.map<String>((f) => f.imageUrl).toList();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    var content = ListView.builder(
      itemBuilder: (_, int index) {
        var page = pages[index];

        Widget pageWidget;
        return Container(
          margin: EdgeInsets.all(20.0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  (index + 1).toString() +
                      "." +
                      page.type.toString().replaceAll("PageType.", ""),
                  //style: TextStyle(inherit: false),
                ),
                Text(
                  page.description,
                  style: TextStyle(color: Colors.grey),
                )
              ],
            ),
            onTap: () {
              switch (page.type) {
                case PageType.Text:
                  pageWidget = new TextDemo();
                  break;
                case PageType.CustomImage:
                  pageWidget = new CustomImageDemo();
                  break;
                case PageType.BackgroundText:
                  pageWidget = new BackgroundTextDemo();
                  break;
                case PageType.CustomTextOverflow:
                  pageWidget = new CustomTextOverflowDemo();
                  break;
                default:
                  break;
              }
              Navigator.push(context,
                  new MaterialPageRoute(builder: (BuildContext context) {
                return pageWidget;
              }));
            },
          ),
        );
      },
      itemCount: pages.length,
    );

    return Scaffold(
      body: content,
    );
  }
}

class Page {
  final PageType type;
  final String description;
  Page(this.type, this.description);
}

enum PageType { Text, CustomImage, BackgroundText, CustomTextOverflow }

List<String> _imageTestUrls;
List<String> get imageTestUrls =>
    _imageTestUrls ??
    <String>["https://photo.tuchong.com/4870004/f/298584322.jpg"];

void clearMemoryImageCache() {
  PaintingBinding.instance.imageCache.clear();
}

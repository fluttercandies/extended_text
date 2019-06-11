import 'package:example/background_text_demo.dart';
import 'package:example/common/tu_chong_repository.dart';
import 'package:example/custom_text_overflow_demo.dart';
import 'package:example/custom_image_demo.dart';
import 'package:example/text_demo.dart';
import 'package:extended_image_library/extended_image_library.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker_saver/image_picker_saver.dart';

import 'text_selection_demo.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
        child: MaterialApp(
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
    ));
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
    clearMemoryImageCache();
    pages.add(Page(PageType.text, "quickly build special text"));
    pages.add(Page(PageType.selection, "text selection support"));
    pages.add(Page(PageType.customImage, "custom inline-image in text"));
    pages.add(Page(PageType.backgroundText,
        "workaround for issue 24335/24337 about background"));
    pages.add(Page(PageType.customTextOverflow,
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
                case PageType.text:
                  pageWidget = TextDemo();
                  break;
                case PageType.customImage:
                  pageWidget = CustomImageDemo();
                  break;
                case PageType.backgroundText:
                  pageWidget = BackgroundTextDemo();
                  break;
                case PageType.customTextOverflow:
                  pageWidget = CustomTextOverflowDemo();
                  break;
                case PageType.selection:
                  pageWidget = TextSelectionDemo();
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

    return MaterialApp(
      builder: (c, w) {
        ScreenUtil.instance =
            ScreenUtil(width: 750, height: 1334, allowFontScaling: true)
              ..init(c);
        var data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(textScaleFactor: 1.0),
          child: Scaffold(
            body: w,
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                ///clear memory
                clearMemoryImageCache();

                ///clear local cahced
                clearDiskCachedImages().then((bool done) {
                  showToast(done ? "clear succeed" : "clear failed",
                      position: ToastPosition(align: Alignment.center));
                });
              },
              child: Text(
                "clear cache",
                textAlign: TextAlign.center,
                style: TextStyle(
                  inherit: false,
                ),
              ),
            ),
          ),
        );
      },
      home: content,
    );
  }
}

class Page {
  final PageType type;
  final String description;
  Page(this.type, this.description);
}

enum PageType {
  text,
  customImage,
  backgroundText,
  customTextOverflow,
  selection
}

List<String> _imageTestUrls;
List<String> get imageTestUrls =>
    _imageTestUrls ??
    <String>["https://photo.tuchong.com/4870004/f/298584322.jpg"];

///save netwrok image to photo
Future<bool> saveNetworkImageToPhoto(String url, {bool useCache: true}) async {
  var data = await getNetworkImageData(url, useCache: useCache);
  var filePath = await ImagePickerSaver.saveFile(fileData: data);
  return filePath != null && filePath != "";
}

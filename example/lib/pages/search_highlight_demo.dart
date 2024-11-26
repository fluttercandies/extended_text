import 'package:example/text/highlight_text_span_builder.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';

@FFRoute(
  name: 'fluttercandies://SearchHighlightDemo',
  routeName: 'SearchHighlightDemo',
  description:
      'show how to highlight text when searching. TextOverflowPosition.auto',
)
class SearchHighlightDemo extends StatefulWidget {
  const SearchHighlightDemo({super.key});

  @override
  State<SearchHighlightDemo> createState() => _SearchHighlightDemoState();
}

class _SearchHighlightDemoState extends State<SearchHighlightDemo> {
  List<String> searchMessages = <String>[
    ...messages,
  ];
  String searchText = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('quickly build special text'),
      ),
      body: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              TextField(
                onChanged: (String value) {
                  searchText = value;
                  setState(
                    () {
                      searchMessages.clear();
                      if (value.isEmpty) {
                        searchMessages.addAll(messages);
                      } else {
                        final RegExp regex =
                            RegExp(value, caseSensitive: false);
                        for (final String message in messages) {
                          if (message
                              .toLowerCase()
                              .contains(value.toLowerCase())) {
                            final RegExpMatch? match =
                                regex.firstMatch(message);
                            if (match != null) {
                              final String highlightedMessage =
                                  message.replaceFirst(
                                regex,
                                HighlightText.getHighlightString(
                                    match.group(0)!),
                              );
                              searchMessages.add(highlightedMessage);
                            }
                          }
                        }
                      }
                    },
                  );
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext b) {
                              return AlertDialog(
                                title: const Text('FullText'),
                                content: ExtendedText(
                                  searchMessages[index],
                                  specialTextSpanBuilder:
                                      HighlightTextSpanBuilder(),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(b);
                                      },
                                      child: const Text('OK'))
                                ],
                              );
                            });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(border: Border.all()),
                        child: ExtendedText(
                          searchMessages[index],
                          specialTextSpanBuilder: HighlightTextSpanBuilder(),
                          maxLines: searchText.isEmpty ? 3 : 1,
                          overflowWidget: TextOverflowWidget(
                            child: const Text('\u2026 '),
                            position: searchText.isEmpty
                                ? TextOverflowPosition.end
                                : TextOverflowPosition.auto,
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: searchMessages.length,
                ),
              ),
            ],
          )),
    );
  }
}

const List<String> messages = <String>[
  '【翼支付】尊敬的用户，您有2元话费券未使用，将于5天内失效，点击查看，如已使用请忽略！拒收请回复R',
  '气象台下周天气预报：17日阴到多云有短时小雨转多云到阴15到18度；18日阴到多云，局部有短时小雨转阴到多云12到15度；19日多云到阴转多云12到15度；20日多云12到17度；21日多云到晴13到17度；22日多云12到17度；23日阴到多云转阴到多云有短时小雨13到18度。【中国移动　气象助手】',
  '气象台15日6时：阴到多云有时有阵雨，今上午以前大部地区有雾。东北风3-4级，明转偏北风4-5级。23-19度。我台已发布大雾黄色预警。【中国移动　气象助手】',
  '防汛防台安全提示：“贝碧嘉”将近，请关注天气；暴雨来临，减少出行；确需开车，遇水绕行；注意坠物，减少伤害；人人关注防汛、人人知晓防汛、人人参与防汛。【市防汛指挥部办公室】',
  '市通管局、市反诈中心提醒：警惕邮寄黄金诈骗。近期，诈骗分子以各种名义，诱骗群众购买并邮寄实物黄金的案件呈上升趋势，请广大市民群众谨防被骗。',
  '【中国电信积分商城】尊敬的用户，您的 爱奇艺 VIP会员黄金月卡 已充值成功，使用充值账号登录即可享受会员权益。如尚未注册，使用充值号码完成注册后登录即可。关注微信“天翼积分”公众号 ，在个人中心查看订单详情！',
  '【人口普查】依法配合人口普查是每个公民应尽的义务。10月11日起，本市普查指导员和普查员将佩戴统一证件入户开展普查摸底，需要您的支持和配合！',
  '上海海警局提醒您：5月1日起，上海海域进入海洋伏季休渔期。请自觉遵守伏季休渔制度，切勿在通信海缆保护区内从事挖砂、钻探、抛锚、拖锚、底拖捕捞、张网及其他可能危及通信海缆安全的海上作业，积极配合执法部门开展日常执法工作，切实保护海底电缆管道及海洋渔业资源。欢迎通过95110海上报警电话提供违法违规线索。',
  '【开放原子】您好，第二届开放原子大赛已正式启动，大赛覆盖基础软件、工业软件、人工智能大模型、创新应用等多个技术领域，设置巅峰挑战赛、实战竞技赛、训练学习赛等不同难度的赛项类型，总奖金约1500万元。登录大赛官网，查看更多比赛信息。拒收请回复R',
  '【Apple】Apple 账户代码为：117409。请勿与他人共享。',
  '【饿了么】您在:炭小签·贵阳特色烧烤下的订单正在加急调度骑士中,恳请您耐心等待！',
];

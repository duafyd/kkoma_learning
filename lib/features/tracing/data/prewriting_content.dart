import 'dart:math' as math;

import '../../learning/domain/learning_models.dart';
import '../domain/trace_engine.dart';
export '../domain/prewriting_strategy.dart';

/// Separate from letters: readiness play never asks a toddler to name a glyph.
final prewritingItems = <LearningItem>[
  _item('dot', '톡', '빛나는 점을 톡 눌러요', const [
    TracePoint(.48, .5),
    TracePoint(.52, .5),
  ]),
  _item('line', '가로길', '왼쪽에서 오른쪽으로 길을 이어요', const [
    TracePoint(.2, .5),
    TracePoint(.8, .5),
  ]),
  _item('down', '세로길', '위에서 아래로 빗방울 길을 이어요', const [
    TracePoint(.5, .2),
    TracePoint(.5, .8),
  ]),
  _item('circle', '동그라미', '빙글 돌아 동그란 길을 만나요', [
    for (var i = 0; i <= 64; i++)
      TracePoint(
        .5 + .28 * math.cos(-math.pi / 2 - i * math.pi / 32),
        .5 + .28 * math.sin(-math.pi / 2 - i * math.pi / 32),
      ),
  ]),
  _item('wave', '물결길', '언덕을 오르내리듯 천천히 이어요', [
    for (var i = 0; i <= 64; i++)
      TracePoint(.15 + i * .7 / 64, .5 - .18 * math.sin(i * math.pi * 2 / 64)),
  ]),
  _item('zigzag', '산길', '뾰족한 산길을 따라 올라갔다 내려와요', const [
    TracePoint(.18, .7),
    TracePoint(.39, .3),
    TracePoint(.61, .7),
    TracePoint(.82, .3),
  ]),
];
LearningItem _item(
  String id,
  String name,
  String instruction,
  List<TracePoint> path,
) => LearningItem(
  id: 'p-$id',
  subject: 'prewriting',
  symbol: name,
  name: name,
  example: instruction,
  picture: '✦',
  minimumLevel: 2,
  strokes: [StrokePath(path)],
);

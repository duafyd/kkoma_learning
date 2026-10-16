/// Event backgrounds for all twelve chapters plus four shared world themes.
const storyArtAssets = {
  'ep1-quiet': 'assets/story/ep1-quiet.png',
  'ep1-search': 'assets/story/ep1-search.png',
  'ep1-map': 'assets/story/ep1-map.png',
  'ep2-gate': 'assets/story/ep2-gate.png',
  'ep2-open': 'assets/story/ep2-open.png',
  'ep3-tree': 'assets/story/ep3-tree.png',
  'ep3-seeds': 'assets/story/ep3-seeds.png',
  'ep4-station': 'assets/story/ep4-station.png',
  'ep4-ready': 'assets/story/ep4-ready.png',
  'ep5-dark': 'assets/story/ep5-dark.png',
  'ep5-lit': 'assets/story/ep5-beam-v2.png',
  'ep6-bridge': 'assets/story/ep6-bridge.png',
  'ep7-faded': 'assets/story/ep7-faded.png',
  'ep8-scattered': 'assets/story/ep8-scattered.png',
  'ep9-fork': 'assets/story/ep9-fork.png',
  'ep10-damp': 'assets/story/ep10-damp.png',
  'ep11-empty': 'assets/story/ep11-empty.png',
  'ep12-return': 'assets/story/ep12-return.png',
  'ep6-built': 'assets/story/ep6-built.png',
  'ep7-color': 'assets/story/ep7-color.png',
  'ep8-sorted': 'assets/story/ep8-sorted.png',
  'ep9-joined': 'assets/story/ep9-joined.png',
  'ep10-open': 'assets/story/ep10-open.png',
  'ep11-lit': 'assets/story/ep11-lit.png',
  'ep12-flowers': 'assets/story/ep12-flowers.png',
  'ep12-stars': 'assets/story/ep12-stars.png',
  'library': 'assets/story/stage-library.png',
  'forest': 'assets/story/stage-forest.png',
  'garden': 'assets/story/stage-forest.png',
  'lighthouse': 'assets/story/stage-coast.png',
  'bridge': 'assets/story/stage-coast.png',
  'train': 'assets/story/stage-coast.png',
  'rain': 'assets/story/stage-night.png',
  'sky': 'assets/story/stage-night.png',
  'wind': 'assets/story/stage-night.png',
};
const storyCastAsset = 'assets/story/cast-v2.png';
const storySearchCastAsset = 'assets/story/cast-search-v3.png';
const storyMotionCastAsset = 'assets/story/cast-motion-v1.png';
const storyCharacterCells = {'루루': 0, '토토': 1, '모아': 2, '휙휙': 3};

({double x, double y}) storyArtFocus(String background) =>
    background == 'ep4-station' ? (x: .6, y: .15) : (x: 0.0, y: .15);

/// Centres on the 1536×1024 source art. Letters stay editable, never AI text.
const storyLetterSigns = <String, List<({double x, double y, String text})>>{
  'ep2-gate': [
    (x: .435, y: .292, text: 'ㅏ'),
    (x: .574, y: .292, text: 'ㅓ'),
    (x: .435, y: .465, text: 'ㅗ'),
    (x: .574, y: .465, text: 'ㅜ'),
  ],
  'ep2-open': [
    (x: .285, y: .315, text: 'ㅏ'),
    (x: .751, y: .315, text: 'ㅓ'),
    (x: .280, y: .480, text: 'ㅗ'),
    (x: .754, y: .480, text: 'ㅜ'),
  ],
  'ep3-tree': [
    (x: .303, y: .170, text: 'ㄱ'),
    (x: .818, y: .163, text: 'ㄴ'),
    (x: .683, y: .346, text: 'ㅁ'),
  ],
  'ep4-station': [(x: .684, y: .449, text: '가'), (x: .877, y: .461, text: '나')],
  'ep4-ready': [(x: .335, y: .577, text: '가'), (x: .601, y: .583, text: '나')],
  'ep5-dark': [(x: .606, y: .408, text: 'A')],
  'ep5-lit': [(x: .606, y: .408, text: 'A')],
};

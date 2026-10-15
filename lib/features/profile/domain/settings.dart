class ParentSettings {
  final int age, level, minutes, helpAfter, repeats;
  final bool autoRead, help, animations;
  final double voiceVolume, effectsVolume, musicVolume;
  const ParentSettings({
    this.age = 3,
    this.level = 3,
    this.minutes = 20,
    this.helpAfter = 3,
    this.repeats = 1,
    this.autoRead = true,
    this.help = true,
    this.animations = true,
    this.voiceVolume = .7,
    this.effectsVolume = .3,
    this.musicVolume = 0,
  });
  Map<String, dynamic> toJson() => {
    'age': age,
    'level': level,
    'minutes': minutes,
    'helpAfter': helpAfter,
    'repeats': repeats,
    'autoRead': autoRead,
    'help': help,
    'animations': animations,
    'voiceVolume': voiceVolume,
    'effectsVolume': effectsVolume,
    'musicVolume': musicVolume,
  };
  factory ParentSettings.fromJson(Map<String, dynamic> j) => ParentSettings(
    age: (j['age'] as int? ?? 3).clamp(2, 5),
    level: (j['level'] as int? ?? 3).clamp(2, 5),
    minutes: (j['minutes'] as int? ?? 20).clamp(5, 120),
    helpAfter: (j['helpAfter'] as int? ?? 3).clamp(1, 5),
    repeats: (j['repeats'] as int? ?? 1).clamp(1, 3),
    autoRead: j['autoRead'] as bool? ?? true,
    help: j['help'] as bool? ?? true,
    animations: j['animations'] as bool? ?? true,
    voiceVolume: (j['voiceVolume'] as num? ?? .7).toDouble().clamp(0, 1),
    effectsVolume: (j['effectsVolume'] as num? ?? .3).toDouble().clamp(0, 1),
    musicVolume: (j['musicVolume'] as num? ?? 0).toDouble().clamp(0, 1),
  );
  ParentSettings change(String key, Object value) =>
      ParentSettings.fromJson({...toJson(), key: value});
}

class AgeStrategy {
  final int level;
  const AgeStrategy(this.level);
  int get maxCount => [3, 5, 10, 20][level.clamp(2, 5) - 2];
  int get choices => level <= 3 ? 2 : 3;
  int get sceneCount => [4, 6, 8, 10][level.clamp(2, 5) - 2];
  bool get exploration => level == 2;
  double get traceTolerance => [.22, .16, .10, .075][level.clamp(2, 5) - 2];
  bool get requireDirection => level >= 4;
  int adapt(int successes, int failures) => failures >= 2
      ? (level - 1).clamp(2, 5)
      : successes >= 3
      ? (level + 1).clamp(2, 5)
      : level;
}

class UsageRecord {
  final String day;
  final int seconds;
  const UsageRecord(this.day, this.seconds);
  static String dateKey(DateTime now) => '${now.year}-${now.month}-${now.day}';
  UsageRecord accrue(DateTime now, int elapsed) => UsageRecord(
    dateKey(now),
    day == dateKey(now) ? seconds + elapsed : elapsed,
  );
  bool expired(int minutes) => seconds >= minutes * 60;
  Map<String, dynamic> toJson() => {'day': day, 'seconds': seconds};
  factory UsageRecord.fromJson(Map<String, dynamic> j, DateTime now) =>
      UsageRecord(
        j['day'] as String? ?? dateKey(now),
        j['seconds'] as int? ?? 0,
      ).accrue(now, 0);
}

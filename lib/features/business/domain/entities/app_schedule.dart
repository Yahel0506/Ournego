class AppSchedule {
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final int openMinutes; // minutes from midnight
  final int closeMinutes; // minutes from midnight

  const AppSchedule({
    required this.dayOfWeek,
    required this.openMinutes,
    required this.closeMinutes,
  });
}

class BusinessHours {
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final int openMinutes; // minutes from midnight
  final int closeMinutes; // minutes from midnight

  const BusinessHours({
    required this.dayOfWeek,
    required this.openMinutes,
    required this.closeMinutes,
  });
}

/// Why a user reports a business.
///
/// Mirrors `business_reports.reason`. Which reasons can hide a listing, and
/// whether a report counts, is decided by the server and never shown to the
/// client.
enum BusinessReportReason {
  noExists('no_exists'),
  closed('closed'),
  incorrectInfo('incorrect_info'),
  inappropriate('inappropriate'),
  duplicate('duplicate'),
  other('other');

  const BusinessReportReason(this.wire);

  /// The database value.
  final String wire;

  /// `other` needs a note that explains the report.
  bool get requiresNote => this == BusinessReportReason.other;

  /// Parses the database value, or returns `null` for unknown values.
  static BusinessReportReason? tryFromWire(String? value) {
    for (final reason in values) {
      if (reason.wire == value) return reason;
    }
    return null;
  }
}

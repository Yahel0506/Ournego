import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/business/domain/entities/business_report_reason.dart';

/// A rule of `submit_business_report` that rejected the call. [code] is the
/// error message the function raises.
class BusinessReportRuleException implements Exception {
  final String code;

  const BusinessReportRuleException(this.code);

  @override
  String toString() => 'BusinessReportRuleException($code)';
}

class BusinessReportSupabaseDatasource {
  BusinessReportSupabaseDatasource({SupabaseClient? client}) : _client = client;

  static const _ruleCodes = [
    'report_limit_reached',
    'business_not_found',
    'owner_cannot_report',
    'invalid_report',
    'not_authenticated',
  ];

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Calls `submit_business_report`, the only write path.
  Future<void> submitReport({
    required String businessId,
    required BusinessReportReason reason,
    String? note,
  }) async {
    try {
      await _supabase.rpc(
        'submit_business_report',
        params: {
          'p_business_id': businessId,
          'p_reason': reason.wire,
          'p_note': note,
        },
      );
    } on PostgrestException catch (e) {
      for (final code in _ruleCodes) {
        if (e.message.contains(code)) throw BusinessReportRuleException(code);
      }
      rethrow;
    }
  }
}

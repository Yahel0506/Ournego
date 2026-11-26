import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/business/domain/entities/business_confirmation_answer.dart';

class BusinessConfirmationSupabaseDatasource {
  BusinessConfirmationSupabaseDatasource({SupabaseClient? client})
    : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Reads the caller's own row. RLS limits the table to that row, and the
  /// `counted` column is not readable, so the validity rule never leaks.
  Future<BusinessConfirmationAnswer?> getMyAnswer({
    required String businessId,
  }) async {
    final row = await _supabase
        .from('business_confirmations')
        .select('answer')
        .eq('business_id', businessId)
        .maybeSingle();
    return BusinessConfirmationAnswer.tryFromWire(row?['answer'] as String?);
  }

  /// Calls `submit_business_confirmation`, the only write path.
  Future<BusinessConfirmationAnswer> submitAnswer({
    required String businessId,
    required BusinessConfirmationAnswer answer,
  }) async {
    final response = await _supabase.rpc(
      'submit_business_confirmation',
      params: {'p_business_id': businessId, 'p_answer': answer.wire},
    );
    final data = Map<String, dynamic>.from(response as Map);
    return BusinessConfirmationAnswer.tryFromWire(data['answer'] as String?) ??
        answer;
  }
}

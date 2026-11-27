import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/data/datasources/business_report_supabase_datasource.dart';
import 'package:ournego/features/business/data/repositories/business_report_repository_impl.dart';
import 'package:ournego/features/business/domain/entities/business_report_reason.dart';

class _ThrowingDatasource extends BusinessReportSupabaseDatasource {
  _ThrowingDatasource(this.error);

  final Object error;

  @override
  Future<void> submitReport({
    required String businessId,
    required BusinessReportReason reason,
    String? note,
  }) async => throw error;
}

void main() {
  Future<Failure?> failureFor(Object error) async {
    final repository = BusinessReportRepositoryImpl(
      datasource: _ThrowingDatasource(error),
    );
    final result = await repository.submitReport(
      businessId: 'b1',
      reason: BusinessReportReason.noExists,
    );
    return result.fold((failure) => failure, (_) => null);
  }

  test('maps the server rules to domain failures', () async {
    expect(
      await failureFor(
        const BusinessReportRuleException('report_limit_reached'),
      ),
      isA<BusinessReportLimitFailure>(),
    );
    expect(
      await failureFor(const BusinessReportRuleException('business_not_found')),
      isA<BusinessReportUnavailableFailure>(),
    );
    expect(
      await failureFor(const BusinessReportRuleException('not_authenticated')),
      isA<SessionExpiredFailure>(),
    );
    expect(
      await failureFor(const BusinessReportRuleException('invalid_report')),
      isA<ServerFailure>(),
    );
  });

  test('anything else is a server failure', () async {
    expect(
      await failureFor(const PostgrestException(message: 'boom')),
      isA<ServerFailure>(),
    );
  });

  test('a successful call returns unit', () async {
    final repository = BusinessReportRepositoryImpl(
      datasource: _OkDatasource(),
    );
    final result = await repository.submitReport(
      businessId: 'b1',
      reason: BusinessReportReason.closed,
    );
    expect(result.isRight(), isTrue);
  });
}

class _OkDatasource extends BusinessReportSupabaseDatasource {
  @override
  Future<void> submitReport({
    required String businessId,
    required BusinessReportReason reason,
    String? note,
  }) async {}
}

import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/map/data/datasources/supabase_map_datasource.dart';

void main() {
  group('SupabaseMapDatasource.isPublicListing', () {
    test('accepts approved, active listings', () {
      expect(
        SupabaseMapDatasource.isPublicListing({
          'status': 'approved',
          'is_active': true,
        }),
        isTrue,
      );
      expect(
        SupabaseMapDatasource.isPublicListing({
          'status': 'approved',
          'is_active': null,
        }),
        isTrue,
      );
    });

    test('rejects every status other than approved', () {
      for (final status in ['pending', 'rejected', 'withdrawn', null]) {
        expect(
          SupabaseMapDatasource.isPublicListing({
            'status': status,
            'is_active': true,
          }),
          isFalse,
          reason: 'status $status',
        );
      }
    });

    test('rejects listings hidden by account deletion', () {
      expect(
        SupabaseMapDatasource.isPublicListing({
          'status': 'approved',
          'is_active': false,
        }),
        isFalse,
      );
    });
  });
}

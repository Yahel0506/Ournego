import 'package:flutter_test/flutter_test.dart';
import 'package:ournego/features/business/data/datasources/business_supabase_datasource.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';

void main() {
  test('maps Sunday to database day 7 and keeps 24:00 closing time', () {
    final payload = BusinessSupabaseDatasource.submissionRpcArguments(
      businessId: 'listing-id',
      name: 'Tortas Lupita',
      description: 'Tortas al carbón',
      category: 4,
      address: 'Centro, Ciudad Guzmán',
      latitude: 19.7,
      longitude: -103.5,
      phoneNumber: ' ',
      imageObject: 'listing-id/unique.jpg',
      imageUrl: 'https://example.test/unique.jpg',
      hours: const [
        AppSchedule(dayOfWeek: 6, openMinutes: 18 * 60, closeMinutes: 1440),
      ],
    );

    expect(payload, {
      'p_listing': {
        'business_id': 'listing-id',
        'name': 'Tortas Lupita',
        'description': 'Tortas al carbón',
        'type': 4,
        'address': 'Centro, Ciudad Guzmán',
        'latitude': 19.7,
        'longitude': -103.5,
        'phone_number': null,
        'image_object': 'listing-id/unique.jpg',
        'image_url': 'https://example.test/unique.jpg',
      },
      'p_hours': [
        {
          'day_of_week': 7,
          'opening_time': '18:00:00',
          'closing_time': '24:00:00',
        },
      ],
    });
  });
}

import 'package:ournego/features/auth/domain/entities/app_user.dart';

class MockCredentials {
  MockCredentials._();

  static const validEmail = 'qa@ournego.mx';
  static const validPassword = 'ValidPass123!';
  static const invalidEmail = 'invalid@ournego.mx';
  static const invalidPassword = 'wrong-password';
}

class MockUsers {
  MockUsers._();

  static const customer = AppUser(
    uid: 'user-customer-001',
    name: 'Cliente Demo',
    email: 'cliente@ournego.mx',
    phoneNum: '5512345678',
  );

  static const ownerWithBusiness = AppUser(
    uid: 'user-owner-001',
    name: 'Dueno Con Negocio',
    email: 'dueno.negocio@ournego.mx',
    phoneNum: '5599991111',
  );

  static const ownerWithoutBusiness = AppUser(
    uid: 'user-owner-002',
    name: 'Dueno Sin Negocio',
    email: 'dueno.sin.negocio@ournego.mx',
    phoneNum: '5588882222',
  );

  static const expiredSessionUser = AppUser(
    uid: 'user-expired-001',
    name: 'Sesion Expirada',
    email: 'expired@ournego.mx',
  );
}

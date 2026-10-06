// Centralized route name constants for the entire app.
//
// Each feature defines its own route class with static constants.
// This prevents magic strings throughout the codebase and makes
// refactoring routes easier.
//
// Usage:
// ```dart
// context.go(AuthRoutes.login);
// context.push(BusinessRoutes.register);
// ```

// |---------------------------------| \\
// |------ DEBUGGING ROUTES ---------| \\
// |---------------------------------| \\

class DebuggingRoutes {
  DebuggingRoutes._();

  static const debugPanel = '/debug-panel';
}

// |---------------------------------| \\
// |------- AUTH ROUTES -------------| \\
// |---------------------------------| \\

class AuthRoutes {
  // Prevent instantiation
  AuthRoutes._();

  static const authSelection = '/auth-selection';
  static const authCompletion = '/auth-completion';
  static const loginEmail = '/login-email';
  static const passwordRecovery = '/password-recovery';
  static const signupEmail = '/signup-email';
  static const createPassword = '/create-password';
  static const verifyEmail = '/verify-email';
  static const completeProfile = '/complete-profile';
}

// |---------------------------------| \\
// |------- MAP ROUTES --------------| \\
// |---------------------------------| \\

class MapRoutes {
  MapRoutes._();

  static const map = '/map';
  static const businessDetails = '/business/:id';
  static const negocioDeeplink = '/negocio/:id';
}

// |---------------------------------| \\
// |------- BUSINESS ROUTES ---------| \\
// |---------------------------------| \\

class BusinessRoutes {
  BusinessRoutes._();

  static const panel = '/business-panel';
  static const register = '/register-business';
  static const form = '/business-form';
}

// |---------------------------------| \\
// |------- NAVIGATION ROUTES -------| \\
// |---------------------------------| \\

class AppRoutes {
  AppRoutes._();

  static const onboarding = '/onboarding';
  static const community = '/community';
}

// |---------------------------------| \\
// |------- HELPER METHODS ----------| \\
// |---------------------------------| \\

const String _negocioDeepLinkHost = 'www.ournego.com';

/// Helper to generate business details route with ID
String businessDetailsRoute(String businessId) {
  return '/business/$businessId';
}

/// Helper to generate public deep link route with ID
String negocioDeepLinkRoute(String businessId) {
  return '/negocio/$businessId';
}

/// Helper to generate the canonical deep link URL for sharing.
Uri negocioDeepLinkUri(String businessId) {
  return Uri.https(_negocioDeepLinkHost, negocioDeepLinkRoute(businessId));
}

/// Helper to generate the canonical deep link URL string for sharing.
String negocioDeepLinkUrl(String businessId) {
  return negocioDeepLinkUri(businessId).toString();
}

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
// |------- AUTH ROUTES -------------| \\
// |---------------------------------| \\

class AuthRoutes {
  // Prevent instantiation
  AuthRoutes._();

  static const authSelection = '/auth-selection';
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

/// Helper to generate business details route with ID
String businessDetailsRoute(String businessId) {
  return '/business/$businessId';
}

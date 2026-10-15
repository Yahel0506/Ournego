import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/features/auth/data/datasources/supabase_auth_datasource.dart';

/// The error the real Google flow raises for [outcome], or null for `real`.
Object? simulatedGoogleErrorFor(GoogleOutcome outcome) => switch (outcome) {
  GoogleOutcome.real => null,
  GoogleOutcome.canceled => const gsi.GoogleSignInException(
    code: gsi.GoogleSignInExceptionCode.canceled,
  ),
  GoogleOutcome.unavailable => const gsi.GoogleSignInException(
    code: gsi.GoogleSignInExceptionCode.clientConfigurationError,
  ),
  GoogleOutcome.network => http.ClientException(
    'Simulated network failure (debug)',
  ),
  GoogleOutcome.serverError => const AuthException(
    'Simulated server error (debug)',
  ),
};

/// Auth datasource whose Google sign-in can end in a chosen failure. It
/// throws the same exceptions the real flow raises, so the production
/// failure mapping and the screens run unchanged. Success cannot be
/// simulated: it needs a real Google token.
class SimulatedAuthDatasource extends SupabaseAuthDatasource {
  SimulatedAuthDatasource(this.controller);

  final DebugSimulationController controller;

  @override
  Future<void> signInWithGoogle() async {
    final error = simulatedGoogleErrorFor(controller.value.googleOutcome);
    if (error == null) return super.signInWithGoogle();
    throw error;
  }
}

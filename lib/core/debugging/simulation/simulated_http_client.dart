import 'package:http/http.dart' as http;

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';

/// HTTP client that fails or slows down requests according to the active
/// [NetworkMode]. It fails the way a real unreachable network does
/// (`ClientException`), so the app's own error handling runs unchanged.
class SimulatedHttpClient extends http.BaseClient {
  SimulatedHttpClient({
    required NetworkMode Function() mode,
    http.Client? inner,
    this.slowDelay = const Duration(seconds: 4),
  }) : _mode = mode,
       _inner = inner ?? http.Client();

  final NetworkMode Function() _mode;
  final http.Client _inner;
  final Duration slowDelay;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    switch (_mode()) {
      case NetworkMode.offline:
      case NetworkMode.serverUnreachable:
        throw http.ClientException(
          'Simulated network failure (debug)',
          request.url,
        );
      case NetworkMode.slow:
        await Future<void>.delayed(slowDelay);
      case NetworkMode.real:
        break;
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

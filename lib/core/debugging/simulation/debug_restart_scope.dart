import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds everything below it, so the app goes through startup again
/// without closing the process. Does nothing in release builds.
class DebugRestartScope extends StatefulWidget {
  const DebugRestartScope({super.key, required this.builder});

  final WidgetBuilder builder;

  static void restart(BuildContext context) {
    if (!kDebugMode) return;
    context.findAncestorStateOfType<_DebugRestartScopeState>()?._restart();
  }

  @override
  State<DebugRestartScope> createState() => _DebugRestartScopeState();
}

class _DebugRestartScopeState extends State<DebugRestartScope> {
  Key _generation = UniqueKey();

  void _restart() => setState(() => _generation = UniqueKey());

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _generation,
      child: Builder(builder: widget.builder),
    );
  }
}

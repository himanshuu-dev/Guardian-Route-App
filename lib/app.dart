import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuardianRouteApp extends ConsumerStatefulWidget {
  const GuardianRouteApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GuardianRouteAppState();
}

class _GuardianRouteAppState extends ConsumerState<GuardianRouteApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Guardian Route App')));
  }
}

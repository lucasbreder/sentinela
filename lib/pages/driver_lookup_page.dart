import 'package:flutter/material.dart';
import 'package:sentinela/widgets/lookup/driver_lookup.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';

class DriverLookupPage extends StatelessWidget {
  const DriverLookupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InternalScaffold(
      child: DriverLookup(),
    );
  }
}

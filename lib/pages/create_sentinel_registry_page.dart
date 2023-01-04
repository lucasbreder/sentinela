import 'package:flutter/material.dart';
import 'package:sentinela/widgets/create/registry_create.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';

class CreateSentinelRegistryPage extends StatelessWidget {
  const CreateSentinelRegistryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const InternalScaffold(
      child: RegistryCreate(),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sentinela/widgets/create/unit_create.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';
import 'package:sentinela/widgets/title/page_title.dart';

class CreateUnitsPage extends StatelessWidget {
  const CreateUnitsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InternalScaffold(
      child: Column(
        children: const [
          PageTitle(
            title: 'Crie Sua Unidade',
          ),
          UnitCreate()
        ],
      ),
    );
  }
}

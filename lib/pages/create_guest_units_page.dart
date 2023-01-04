import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sentinela/widgets/create/guest_create.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';
import 'package:sentinela/widgets/title/page_title.dart';

class CreateUnitsGuestPage extends StatelessWidget {
  const CreateUnitsGuestPage({Key? key, required this.unitId})
      : super(key: key);

  final String unitId;

  @override
  Widget build(BuildContext context) {
    return InternalScaffold(
      child: Column(
        children: [
          const PageTitle(
            title: 'Conceda Acesso',
          ),
          UnitGuestCreate(
            unitId: unitId,
          )
        ],
      ),
    );
  }
}

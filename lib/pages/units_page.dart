import 'package:flutter/material.dart';
import 'package:sentinela/widgets/list/guest_units_list.dart';
import 'package:sentinela/widgets/list/my_units_list.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';
import 'package:sentinela/widgets/title/page_title.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class UnitsPage extends StatelessWidget {
  const UnitsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InternalScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(
            title: 'Unidades',
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/createUnit');
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.all(
                  Radius.circular(20),
                ),
              ),
              child: const Text(
                'Criar uma unidade',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SecondaryTitle(title: 'Minhas Unidades'),
          const MyUnitsList(),
        ],
      ),
    );
  }
}

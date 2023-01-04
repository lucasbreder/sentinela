import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sentinela/controllers/get_my_units.dart';
import 'package:sentinela/controllers/get_unit.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/models/unit.dart';
import 'package:sentinela/pages/access_unit_page.dart';

class MyUnitsList extends StatefulWidget {
  const MyUnitsList({Key? key}) : super(key: key);

  @override
  State<MyUnitsList> createState() => _MyUnitsListState();
}

class _MyUnitsListState extends State<MyUnitsList> {
  late List<Unit> myUnits;
  final List<Widget> _units = [];

  void renderMyUnits() async {
    List query = await getMyUnits();

    for (var unitData in query) {
      final unit = await getUnit(unitData.get('unit_id'));
      setState(() {
        _units.add(Column(
          children: [
            Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  border: Border.all(
                    color: unitData.get('role') == 'owner'
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.background,
                    width: unitData.get('role') == 'owner' ? 3 : 2,
                  )),
              child: unitData.get('role') == 'owner'
                  ? GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AccessUnitPage(
                              unitId: unit.id,
                              unitName: unit.get('name'),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        unit.get('name'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Text(
                      unit.get('name'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            unitData.get('role') == 'guest' &&
                    unitData.get('expires_at') != null
                ? SizedBox(
                    child: Column(
                      children: [
                        Text(
                          'Acesso até',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.background,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          formatDate(
                              unitData.get('expires_at').toDate().toString()),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.background,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
          ],
        ));
      });
    }
  }

  @override
  void initState() {
    renderMyUnits();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: _units,
    );
  }
}

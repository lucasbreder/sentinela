import 'package:flutter/material.dart';
import 'package:sentinela/controllers/get_unit.dart';
import 'package:sentinela/controllers/get_my_guest_units.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/models/unit.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class GuestUnitsList extends StatefulWidget {
  const GuestUnitsList({Key? key}) : super(key: key);

  @override
  State<GuestUnitsList> createState() => _GuestUnitsListState();
}

class _GuestUnitsListState extends State<GuestUnitsList> {
  late List<Unit> myUnits;
  final List<Widget> _units = [];

  void getGuestUnits() async {
    List query = await getMyGuestUnits();

    for (var unitGuest in query) {
      final unit = await getUnit(unitGuest.get('unit_id'));

      setState(() {
        _units.add(Column(
          children: [
            Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1,
                  )),
              child: Text(
                unit.get('name'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            unitGuest.get('expires_at') != null
                ? SizedBox(
                    child: Column(
                      children: [
                        Text(
                          'Acesso até',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          formatDate(
                              unitGuest.get('expires_at').toDate().toString()),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
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
    getGuestUnits();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _units.isNotEmpty
            ? const SecondaryTitle(title: 'Unidades que tenho acesso')
            : const Text(''),
        Wrap(
          children: _units,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/unit.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/pages/access_unit_page.dart';

class MyUnitsList extends StatefulWidget {
  const MyUnitsList({super.key});

  @override
  State<MyUnitsList> createState() => _MyUnitsListState();
}

class _MyUnitsListState extends State<MyUnitsList> {
  final List<Widget> _units = [];

  Future<void> _loadUnits() async {
    final permissions = await ServiceLocator.instance.units.getMyPermissions();
    if (!mounted) return;

    final widgets = <Widget>[];
    for (final permission in permissions) {
      final Unit unit;
      try {
        unit = await ServiceLocator.instance.units.getUnit(permission.unitId);
      } catch (_) {
        continue;
      }
      widgets.add(_buildUnitTile(permission, unit));
    }

    setState(() {
      _units
        ..clear()
        ..addAll(widgets);
    });
  }

  Widget _buildUnitTile(Permission permission, Unit unit) {
    final isOwner = permission.isOwner;
    final borderColor = isOwner
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surface;
    final borderWidth = isOwner ? 3.0 : 2.0;
    final textColor =
        isOwner ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: isOwner
              ? GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AccessUnitPage(unitId: unit.id, unitName: unit.name),
                      ),
                    );
                  },
                  child: Text(
                    unit.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Text(
                  unit.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        if (permission.isGuest && permission.expiresAt != null)
          Column(
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
                formatDate(permission.expiresAt!),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  void initState() {
    _loadUnits();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(children: _units);
  }
}

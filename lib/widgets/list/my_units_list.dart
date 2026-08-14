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
  String? _error;

  Future<void> _loadUnits() async {
    setState(() {
      _units.clear();
      _error = null;
    });

    final List<Permission> permissions;
    try {
      permissions = await ServiceLocator.instance.units.getMyPermissions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      return;
    }
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
    final color = Theme.of(context).colorScheme.primary;
    final borderWidth = isOwner ? 3.0 : 2.0;
    final textColor = color;

    final content = Text(
      unit.name,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    final tile = Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: color, width: borderWidth),
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
              child: content,
            )
          : content,
    );

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            tile,
            if (!isOwner)
              Positioned(
                top: -4,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Externa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
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
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Erro ao carregar unidades: $_error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _loadUnits,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }
    return Wrap(children: _units);
  }
}

import 'package:flutter/material.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/unit.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/pages/access_unit_page.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class MyUnitsList extends StatefulWidget {
  const MyUnitsList({super.key});

  @override
  State<MyUnitsList> createState() => _MyUnitsListState();
}

class _MyUnitsListState extends State<MyUnitsList> {
  final List<Widget> _units = [];
  final List<Widget> _archivedUnits = [];
  String? _error;

  Future<void> _confirmRemoveAccess(Permission permission) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover acesso'),
        content: Text('Deseja remover seu acesso à unidade ${permission.unitName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ServiceLocator.instance.units.removeMyAccess(permission.unitId);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acesso removido')),
        );
        _loadUnits();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  Future<void> _confirmArchiveUnit(Unit unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar unidade'),
        content: Text('Deseja arquivar a unidade ${unit.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ServiceLocator.instance.units.archiveUnit(unit.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidade arquivada')),
        );
        _loadUnits();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  Future<void> _unarchiveUnit(Unit unit) async {
    final result = await ServiceLocator.instance.units.unarchiveUnit(unit.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidade desarquivada')),
        );
        _loadUnits();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  Future<void> _confirmDeleteUnit(Unit unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir unidade'),
        content: Text(
          'Ao excluir a unidade ${unit.name}, todos os registros vinculados a ela também serão removidos. Essa ação não pode ser desfeita. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ServiceLocator.instance.units.deleteUnit(unit.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidade excluída')),
        );
        _loadUnits();
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  Future<void> _loadUnits() async {
    setState(() {
      _units.clear();
      _archivedUnits.clear();
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

    final active = <Widget>[];
    final archived = <Widget>[];
    for (final permission in permissions) {
      final Unit unit;
      try {
        unit = await ServiceLocator.instance.units.getUnit(permission.unitId);
      } catch (_) {
        continue;
      }
      if (unit.archived) {
        if (permission.isOwner) archived.add(_buildArchivedTile(permission, unit));
        continue;
      }
      active.add(_buildUnitTile(permission, unit));
    }

    setState(() {
      _units
        ..clear()
        ..addAll(active);
      _archivedUnits
        ..clear()
        ..addAll(archived);
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
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AccessUnitPage(unitId: unit.id, unitName: unit.name),
                        ),
                      );
                    },
                    child: content,
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmArchiveUnit(unit),
                  child: Icon(
                    Icons.archive_outlined,
                    color: color,
                    size: 20,
                    semanticLabel: 'Arquivar',
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: content),
                GestureDetector(
                  onTap: () => _confirmRemoveAccess(permission),
                  child: Icon(
                    Icons.logout,
                    color: color,
                    size: 20,
                    semanticLabel: 'Remover meu acesso',
                  ),
                ),
              ],
            ),
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

  Widget _buildArchivedTile(Permission permission, Unit unit) {
    final color = Theme.of(context).colorScheme.primary;

    final tile = Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: color, width: 2.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              unit.name,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _unarchiveUnit(unit),
            child: Icon(
              Icons.unarchive_outlined,
              color: color,
              size: 24,
              semanticLabel: 'Desarquivar',
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _confirmDeleteUnit(unit),
            child: Icon(
              Icons.delete_outline,
              color: color,
              size: 24,
              semanticLabel: 'Excluir unidade',
            ),
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        tile,
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
              'Arquivada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          Text(
            'Erro ao carregar unidades: $_error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: _loadUnits,
            child: const Text('Tentar novamente'),
          ),
        ] else ...[
          Wrap(children: _units),
          if (_archivedUnits.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SecondaryTitle(title: 'Unidades Arquivadas'),
            Wrap(children: _archivedUnits),
          ],
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/profile.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/pages/create_guest_units_page.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';
import 'package:sentinela/widgets/title/page_title.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class AccessUnitPage extends StatefulWidget {
  const AccessUnitPage({super.key, required this.unitId, required this.unitName});

  final String unitId;
  final String unitName;

  @override
  State<AccessUnitPage> createState() => _AccessUnitPageState();
}

class _AccessUnitPageState extends State<AccessUnitPage> {
  final List<Widget> _guestsList = [];

  Future<void> _loadGuests() async {
    final permissions = await ServiceLocator.instance.units.getUnitGuests(widget.unitId);
    if (!mounted) return;

    final widgets = <Widget>[];
    for (final permission in permissions) {
      final Profile? profile =
          await ServiceLocator.instance.profiles.getById(permission.userId);
      widgets.add(_buildGuestTile(permission, profile));
    }

    setState(() {
      _guestsList
        ..clear()
        ..addAll(widgets);
    });
  }

  Widget _buildGuestTile(Permission permission, Profile? profile) {
    final context = this.context;
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final expiresAt = permission.expiresAt;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 1, color: surface)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.name ?? '',
                style: TextStyle(color: primary, fontSize: 18),
              ),
              Text(profile?.email ?? ''),
              Text(profile?.registry ?? ''),
              if (expiresAt != null)
                expiresAt.isAfter(DateTime.now())
                    ? Text(
                        'Acesso até ${formatDate(expiresAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : Text(
                        'Expirado em: ${formatDate(expiresAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
            ],
          ),
          GestureDetector(
            onTap: () => _removeGuest(permission),
            child: Icon(
              Icons.person_remove_outlined,
              color: primary,
              size: 32.0,
              semanticLabel: 'Remover Acesso',
            ),
          )
        ],
      ),
    );
  }

  Future<void> _removeGuest(Permission permission) async {
    await ServiceLocator.instance.units.deleteGuest(widget.unitId, permission.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário removido')),
    );
    setState(() => _guestsList.clear());
    await _loadGuests();
  }

  Future<void> _confirmDeleteUnit() async {
    final result = await ServiceLocator.instance.units.deleteUnit(widget.unitId);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidade Removida')),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.units, (route) => false);
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  @override
  void initState() {
    _loadGuests();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InternalScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PageTitle(title: widget.unitName.isNotEmpty ? widget.unitName : ''),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateUnitsGuestPage(unitId: widget.unitId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Icon(
                    Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 44.0,
                    semanticLabel: 'Conceder Acesso',
                  ),
                ),
              )
            ],
          ),
          const SecondaryTitle(title: 'Usuários com acesso'),
          SingleChildScrollView(
            child: Column(
              children:
                  _guestsList.isNotEmpty ? _guestsList : [const Text('Nenhum usuário')],
            ),
          ),
          GestureDetector(
            onTap: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Deseja excluir essa unidade?'),
                content: const Text('Ao excluir todas as movimentações serão excluidas'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'Cancel'),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteUnit();
                    },
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(
                'Excluir Unidade',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

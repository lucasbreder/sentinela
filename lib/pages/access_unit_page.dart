import 'package:flutter/material.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/invite.dart';
import 'package:sentinela/data/models/permission.dart';
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
  List<Permission> _guests = [];
  List<Invite> _invites = [];
  bool _loading = true;

  Future<void> _load() async {
    final permissions = await ServiceLocator.instance.units.getUnitGuests(widget.unitId);
    final invites = await ServiceLocator.instance.units.getUnitInvites(widget.unitId);
    if (!mounted) return;
    setState(() {
      _guests = permissions;
      _invites = invites;
      _loading = false;
    });
  }

  String _labelFor(String? email) => email == null || email.isEmpty ? 'Sem e-mail' : email;

  Widget _expiryText(DateTime? expiresAt) {
    if (expiresAt == null) return const SizedBox.shrink();
    return expiresAt.isAfter(DateTime.now())
        ? Text(
            'Acesso até ${formatDate(expiresAt)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          )
        : Text(
            'Expirado em: ${formatDate(expiresAt)}',
            style: const TextStyle(fontSize: 12, color: Colors.red),
          );
  }

  Future<void> _removeGuest(Permission permission) async {
    await ServiceLocator.instance.units.deleteGuest(widget.unitId, permission.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Acesso removido')),
    );
    await _load();
  }

  Future<void> _removeInvite(Invite invite) async {
    final result =
        await ServiceLocator.instance.units.deleteInvite(widget.unitId, invite.email);
    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convite removido')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      ),
    );
    await _load();
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
    _load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
                    color: primary,
                    size: 44.0,
                    semanticLabel: 'Convidar',
                  ),
                ),
              )
            ],
          ),
          if (_invites.isNotEmpty) ...[
            const SecondaryTitle(title: 'Convites Pendentes'),
            for (final invite in _invites)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(invite.email),
                trailing: GestureDetector(
                  onTap: () => _removeInvite(invite),
                  child: Icon(Icons.close, color: primary, semanticLabel: 'Remover convite'),
                ),
              ),
          ],
          const SecondaryTitle(title: 'Usuários com acesso'),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            )
          else if (_guests.isEmpty)
            const Text('Nenhum usuário')
          else
            for (final permission in _guests)
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
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
                          _labelFor(permission.email),
                          style: TextStyle(color: primary, fontSize: 18),
                        ),
                        _expiryText(permission.expiresAt),
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
                    ),
                  ],
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
                border: Border.all(color: primary, width: 1),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(
                'Excluir Unidade',
                style: TextStyle(color: primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

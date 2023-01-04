import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sentinela/controllers/delete_unit.dart';
import 'package:sentinela/controllers/delete_unit_guest.dart';
import 'package:sentinela/controllers/get_unit_guests.dart';
import 'package:sentinela/controllers/get_user_profile_by_id.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/pages/create_guest_units_page.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';
import 'package:sentinela/widgets/title/page_title.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class AccessUnitPage extends StatefulWidget {
  const AccessUnitPage({Key? key, required this.unitId, required this.unitName})
      : super(key: key);

  final String unitId;
  final String unitName;

  @override
  State<AccessUnitPage> createState() => _AccessUnitPageState();
}

class _AccessUnitPageState extends State<AccessUnitPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  List<Widget> _guestsList = [];

  void getGuests() async {
    final QuerySnapshot units = await getUnitGuests(widget.unitId);

    for (var guest in units.docs) {
      final DocumentSnapshot userProfile =
          await getUserProfileById(guest.get('user_id'));
      setState(() {
        _guestsList.add(Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              border: Border(
            bottom: BorderSide(
                width: 1, color: Theme.of(context).colorScheme.background),
          )),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProfile.get('name'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18),
                  ),
                  Text(
                    userProfile.get('email'),
                  ),
                  Text(
                    userProfile.get('registry'),
                  ),
                  guest.get('expires_at') != null
                      ? guest.get('expires_at').toDate().isAfter(DateTime.now())
                          ? Text(
                              "Acesso até ${formatDate(guest.get('expires_at').toDate().toString())}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            )
                          : Text(
                              "Expirado em: ${formatDate(guest.get('expires_at').toDate().toString())}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            )
                      : const SizedBox()
                ],
              ),
              GestureDetector(
                onTap: (() {
                  deleteUnitGuest(widget.unitId, guest.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuário removido'),
                    ),
                  );
                  setState(() {
                    _guestsList = [];
                    getGuests();
                  });
                }),
                child: Icon(
                  Icons.person_remove_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32.0,
                  semanticLabel: 'Remover Acesso',
                ),
              )
            ],
          ),
        ));
      });
    }
  }

  @override
  void initState() {
    getGuests();
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
                PageTitle(
                  title: widget.unitName.isNotEmpty ? widget.unitName : '',
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => CreateUnitsGuestPage(
                                unitId: widget.unitId,
                              )),
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
              ]),
          const SecondaryTitle(title: 'Usuários com acesso'),
          SingleChildScrollView(
            child: Column(
              children: _guestsList.isNotEmpty
                  ? _guestsList
                  : [const Text('Nenhum usuário')],
            ),
          ),
          GestureDetector(
            onTap: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Deseja excluir essa unidade?'),
                content: const Text(
                    'Ao excluir todas as movimentações serão excluidas'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'Cancel'),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () async {
                      String resultDelete = await deleteUnit(widget.unitId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(resultDelete)),
                      );
                      Navigator.pushNamed(context, '/units');
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
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 1),
                borderRadius: const BorderRadius.all(
                  Radius.circular(20),
                ),
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

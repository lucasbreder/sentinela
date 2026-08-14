import 'package:flutter/material.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/invite.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class PendingInvites extends StatefulWidget {
  const PendingInvites({super.key});

  @override
  State<PendingInvites> createState() => _PendingInvitesState();
}

class _PendingInvitesState extends State<PendingInvites> {
  late Future<List<Invite>> _future;

  @override
  void initState() {
    super.initState();
    _future = ServiceLocator.instance.units.getPendingInvites();
  }

  Future<void> _accept(Invite invite) async {
    final result =
        await ServiceLocator.instance.units.acceptInvite(invite.unitId);
    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acesso concedido')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      ),
    );
    setState(() {
      _future = ServiceLocator.instance.units.getPendingInvites();
    });
  }

  Future<void> _decline(Invite invite) async {
    final result =
        await ServiceLocator.instance.units.declineInvite(invite.unitId);
    if (!mounted) return;
    result.when(
      success: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convite recusado')),
      ),
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      ),
    );
    setState(() {
      _future = ServiceLocator.instance.units.getPendingInvites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Invite>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SecondaryTitle(title: 'Convites Pendentes'),
              Text(
                'Erro ao carregar convites: ${snapshot.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _future = ServiceLocator.instance.units.getPendingInvites();
                }),
                child: const Text('Tentar novamente'),
              ),
            ],
          );
        }
        final invites = snapshot.data ?? const <Invite>[];
        if (snapshot.connectionState != ConnectionState.done ||
            invites.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SecondaryTitle(title: 'Convites Pendentes'),
            for (final invite in invites)
              ListTile(
                title: Text(invite.unitName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _decline(invite),
                      child: const Text('Recusar'),
                    ),
                    ElevatedButton(
                      onPressed: () => _accept(invite),
                      child: const Text('Aceitar'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

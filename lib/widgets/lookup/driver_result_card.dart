import 'package:flutter/material.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/helpers/format_date.dart';

class DriverResultCard extends StatelessWidget {
  const DriverResultCard({super.key, required this.registry});

  final Registry registry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEntrada = registry.type == MovementType.entrada;
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 1),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  registry.licensePlate,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (isEntrada)
                const Icon(Icons.login, color: Color(0xFF2E7D32))
              else
                const Icon(Icons.logout, color: Color(0xFFB54022)),
            ],
          ),
          const SizedBox(height: 12),
          _Field(label: 'Condutor', value: registry.driver),
          _Field(label: 'Documento', value: registry.documentNumber),
          _Field(label: 'Data e hora', value: formatDate(registry.createdAt)),
          if (registry.notes.isNotEmpty)
            _Field(label: 'Observações', value: registry.notes),
          if (registry.authorName != null)
            _Field(label: 'Registrado por', value: registry.authorName!),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

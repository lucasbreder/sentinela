import 'package:flutter/material.dart';
import 'package:sentinela/data/models/unit.dart';

class UnitSelector extends StatelessWidget {
  const UnitSelector({
    super.key,
    required this.units,
    required this.selectedUnitId,
    required this.onSelected,
  });

  final List<Unit> units;
  final String selectedUnitId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final data in units)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _UnitTile(
              label: data.name,
              selected: selectedUnitId == data.id,
              onTap: () => onSelected(data.id),
            ),
          ),
      ],
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            width: selected ? 2 : 1,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
        ),
        padding: const EdgeInsets.all(12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════════════
// STAT CHIP
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  final String label;
  final String desc;
  const StatChip({required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

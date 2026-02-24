import 'package:flutter/material.dart';

class ServiceLegend extends StatelessWidget {
  const ServiceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Auto-selección: ', style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(width: 6),
            _ServiceChip('Catbox', '≤500GB', '♾️ permanente', Colors.purple),
            const SizedBox(width: 6),
            _ServiceChip('Litterbox', '≤5GB', '72h', Colors.blue),
            const SizedBox(width: 6),
            _ServiceChip('Filebin', 'ilimitado', '6 días', Colors.orange),
            const SizedBox(width: 6),
            _ServiceChip('Transfer.sh', 'ilimitado', '14 días', Colors.teal),
          ],
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String name;
  final String limit;
  final String duration;
  final Color color;

  const _ServiceChip(this.name, this.limit, this.duration, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          Text('$limit · $duration', style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
